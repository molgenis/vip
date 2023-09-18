#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

BCFTOOLS_CMD="apptainer exec --bind /groups /apps/data/vip/v3.2.0/sif/BCFtools.sif bcftools"
BGZIP_CMD="apptainer exec --bind /groups /apps/data/vip/v3.2.0/sif/HTSlib.sif bgzip"
TABIX_CMD="apptainer exec --bind /groups /apps/data/vip/v3.2.0/sif/HTSlib.sif tabix"

ASSEMBLY="GRCh38"
THREADS=4

chromosomes=("chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY")

download() {
        local -r output_dir="${SCRIPT_DIR}/${ASSEMBLY}/downloads"
        mkdir -p "${output_dir}"

	local download_file=""
        local output_path=""

        for chromosome in "${chromosomes[@]}"
        do
		download_file="gnomad.genomes.v3.1.2.sites.${chromosome}.vcf.bgz"
                output_path="${output_dir}/gnomad.genomes.v3.1.2.sites.${chromosome}.vcf.bgz"
                if [[ ! -f "${output_path}" ]]; then
                        wget -c https://storage.googleapis.com/gcp-public-data--gnomad/release/3.1.2/vcf/genomes/${download_file} -O "${output_path}"
                else
                        echo "  skipping download '${download_file}' because file already exists"
                fi
        done
}

process() {

	local -r input_dir="${SCRIPT_DIR}/${ASSEMBLY}/downloads"
	local -r output_dir="${SCRIPT_DIR}/${ASSEMBLY}/intermediates"
	mkdir -p "${output_dir}"

	local input_path=""
	local output_path=""

  local -r rename_path="${output_dir}/rename.txt"
	if [[ ! -f "${rename_path}" ]]; then
		echo -e "INFO/nhomalt HN\n" > "${rename_path}"
	fi

	output_files=()
	for chromosome in "${chromosomes[@]}"
	do
		echo "  processing chromosome ${chromosome} ..."

		input_path="${input_dir}/gnomad.genomes.v3.1.2.sites.${chromosome}.vcf.bgz"
		output_path="${output_dir}/gnomad.genomes.v3.1.2.sites.${chromosome}.stripped.vcf.gz"
			
		if [[ ! -f "${output_path}" ]]; then
			${BCFTOOLS_CMD} filter --no-version -i "(filter==\"PASS\" || filter==\".\")" -Ou "${input_path}" | \
			${BCFTOOLS_CMD} annotate --no-version -x ID,QUAL,FILTER,^INFO/AF,INFO/nhomalt --rename-annots "${rename_path}" -Oz --threads "${THREADS}" -o "${output_path}"
			${BCFTOOLS_CMD} index "${output_path}"
		else
			echo "    skip stripping for '${chromosome}' because file already exists"
		fi

		output_files+=("${output_path}")		
		echo "  processing chromosome ${chromosome} done"
	done

	local -r total_output_path="${SCRIPT_DIR}/${ASSEMBLY}/gnomad.genomes.v3.1.2.sites.stripped.vcf.gz"
	if [[ ! -f "${total_output_path}" ]]; then
		${BCFTOOLS_CMD} concat --no-version -Ov "${output_files[@]}" | ${BGZIP_CMD} -l 9 -@ "${THREADS}" > "${total_output_path}"
		${BCFTOOLS_CMD} index "${total_output_path}"
	else
		echo "   skip concatting to ${total_output_path} because file already exists"
	fi
}

convert() {
	local -r input="${SCRIPT_DIR}/${ASSEMBLY}/gnomad.genomes.v3.1.2.sites.stripped.vcf.gz"
	local -r output="${SCRIPT_DIR}/${ASSEMBLY}/gnomad.genomes.v3.1.2.sites.stripped.tsv.gz"
	if [[ ! -f "${total_output_path}" ]]; then
		${BCFTOOLS_CMD} query --print-header --format '%CHROM\t%POS\t%REF\t%ALT\t%INFO/AF\t%INFO/HN\n' "${input}" |\
	      ${BGZIP_CMD} --stdout --compress-level 9 --threads "${THREADS}" > "${output}"
    	${TABIX_CMD} "${output}" --begin 2 --end 2 --sequence 1 --skip-lines 1
	else
		echo "   skip converting to ${output} because file already exists"
	fi
}

main() {
	echo "downloading files ..."
	download
	echo "downloading files done"

	echo "processing ..."
	process
	echo "processing done"

	echo "convert ..."
	process
	echo "converting done"
}

main "${@}"

