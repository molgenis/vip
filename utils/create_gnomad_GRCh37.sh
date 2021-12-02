#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")

BCFTOOLS_CMD="singularity exec --bind /groups /apps/data/vip/v3.2.0/sif/BCFtools.sif bcftools"
BGZIP_CMD="singularity exec --bind /groups /apps/data/vip/v3.2.0/sif/HTSlib.sif bgzip"

ASSEMBLY="GRCh37"
THREADS=4

# No MT available for GRCh37
chromosomes=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "X" "Y")
methods=("exomes" "genomes")

download() {
        local -r output_dir="${SCRIPT_DIR}/${ASSEMBLY}/downloads"
        mkdir -p "${output_dir}"

	local download_file=""
        local output_path=""

        for chromosome in "${chromosomes[@]}"
        do
                for method in "${methods[@]}"
                do
                        if [[ "${chromosome}" == "Y" ]] && [[ "${method}" == "genomes" ]]; then
                                continue
                        fi

			download_file="gnomad.${method}.r2.1.1.sites.${chromosome}.vcf.bgz"
                        output_path="${output_dir}/gnomad.${method}.r2.1.1.sites.${chromosome}.vcf.bgz"
                        if [[ ! -f "${output_path}" ]]; then
                                wget -c https://storage.googleapis.com/gcp-public-data--gnomad/release/2.1.1/vcf/${method}/${download_file} -O "${output_path}"
                        else
                                echo "  skipping download '${download_file}' because file already exists"
                        fi
                done
        done
}

process() {

	local -r input_dir="${SCRIPT_DIR}/${ASSEMBLY}/downloads"
	local -r output_dir="${SCRIPT_DIR}/${ASSEMBLY}/intermediates"
	mkdir -p "${output_dir}"

	local input_path=""
	local output_path=""

	local -r rename_path="${output_dir}/rename.txt"
	local -r rename_revert_path="${output_dir}/rename_revert.txt"

	if [[ ! -f "${rename_path}" ]]; then
		echo -e "INFO/AC GAC\nINFO/AN GAN\n" > "${rename_path}"
	fi
	if [[ ! -f "${rename_revert_path}" ]]; then
		echo -e "INFO/GAC AC\nINFO/GAN AN\n" > "${rename_revert_path}"
	fi

	output_files=()
	for chromosome in "${chromosomes[@]}"
	do
		echo "  processing chromosome ${chromosome} ..."
	 	for method in "${methods[@]}"
		do
			if [[ "${chromosome}" == "Y" ]] && [[ "${method}" == "genomes" ]]; then
				continue
			fi

			input_path="${input_dir}/gnomad.${method}.r2.1.1.sites.${chromosome}.vcf.bgz"
			output_path="${output_dir}/gnomad.${method}.r2.1.1.sites.${chromosome}.stripped.renamed.vcf.gz"
			
			if [[ ! -f "${output_path}" ]]; then
				input_path_stripped="${output_dir}/gnomad.${method}.r2.1.1.sites.${chromosome}.stripped.vcf.gz"
				if [[ -f "${input_path_stripped}" ]]; then
					echo "    skip stripping for '${method}' because file already exists"

					${BCFTOOLS_CMD} annotate --no-version --rename-annots "${rename_path}" -Oz --threads "${THREADS}" "${input_path_stripped}" -o "${output_path}"
				else 
					# workaround: rename fields because of https://github.com/samtools/bcftools/issues/1394
					${BCFTOOLS_CMD} filter --no-version -i "(filter==\"PASS\" || filter==\".\")" -Ou "${input_path}" | \
					${BCFTOOLS_CMD} annotate --no-version -x ID,QUAL,FILTER,^INFO/AC,INFO/AN --rename-annots "${rename_path}" -Oz --threads "${THREADS}" -o "${output_path}"
				fi
				${BCFTOOLS_CMD} index "${output_path}"
			else
				echo "    skip stripping and renaming for '${method}' because file already exists"
			fi
 		done
		
		input_path_exomes="${output_dir}/gnomad.exomes.r2.1.1.sites.${chromosome}.stripped.renamed.vcf.gz"
		input_path_genomes="${output_dir}/gnomad.genomes.r2.1.1.sites.${chromosome}.stripped.renamed.vcf.gz"
		output_path="${output_dir}/gnomad.total.r2.1.1.sites.${chromosome}.stripped.vcf.gz"
		
		if [[ ! -f "${output_path}" ]]; then
			if [[ "${chromosome}" != "Y" ]]; then
				# workaround: undo rename fields
				${BCFTOOLS_CMD} merge --no-version -m none -i GAC:sum,GAN:sum "${input_path_exomes}" "${input_path_genomes}" -Ou | \
				${BCFTOOLS_CMD} annotate --no-version --rename-annots "${rename_revert_path}" -Ou | \
				${BCFTOOLS_CMD} +fill-tags --no-version -Ou -- -t AF | \
				${BCFTOOLS_CMD} annotate --no-version -x ^INFO/AF -Oz --threads "${THREADS}" -o "${output_path}"
			else
				# workaround: undo rename fields
                        	${BCFTOOLS_CMD} annotate --no-version --rename-annots "${rename_revert_path}" -Ou "${input_path_exomes}" | \
				${BCFTOOLS_CMD} +fill-tags --no-version -Ou -- -t AF | \
				${BCFTOOLS_CMD} annotate --no-version -x ^INFO/AF -Oz --threads "${THREADS}" -o "${output_path}"
			fi
			${BCFTOOLS_CMD} index "${output_path}"
		else
			echo "    skip merging for '${chromosome}' because file already exists"
		fi
		
		output_files+=("${output_path}")
		
		echo "  processing chromosome ${chromosome} done"
	done

	local -r total_output_path="${SCRIPT_DIR}/${ASSEMBLY}/gnomad.total.r2.1.1.sites.stripped.vcf.gz"
	if [[ ! -f "${total_output_path}" ]]; then
		${BCFTOOLS_CMD} concat --no-version -Ov "${output_files[@]}" | ${BGZIP_CMD} -l 9 -@ "${THREADS}" > "${total_output_path}"
		${BCFTOOLS_CMD} index "${total_output_path}"
	else
		echo "   skip concatting to ${total_output_path} because file already exists"
	fi
}

main() {
	echo "downloading files ..."
	download
	echo "downloading files done"

	echo "processing ..."
	process
	echo "processing done"
}

main "${@}"

# command to calculate AF
# ${BCFTOOLS_CMD} +fill-tags -- -t AF

