#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")

BCFTOOLS_CMD="singularity exec --bind /groups /apps/data/vip/v3.2.0/sif/BCFtools.sif bcftools"
BGZIP_CMD="singularity exec --bind /groups /apps/data/vip/v3.2.0/sif/HTSlib.sif bgzip"

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
		download_file="gnomad.genomes.v3.1.1.sites.${chromosome}.vcf.bgz"
                output_path="${output_dir}/gnomad.genomes.v3.1.1.sites.${chromosome}.vcf.bgz"
                if [[ ! -f "${output_path}" ]]; then
			wget -c https://storage.googleapis.com/gcp-public-data--gnomad/release/3.1.1/vcf/genomes/gnomad.genomes.v3.1.1.sites.chr1.vcf.bgz
                        wget -c https://storage.googleapis.com/gcp-public-data--gnomad/release/2.1.1/vcf/genomes/${download_file} -O "${output_path}"
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

	output_files=()
	for chromosome in "${chromosomes[@]}"
	do
		echo "  processing chromosome ${chromosome} ..."

		input_path="${input_dir}/gnomad.genomes.v3.1.1.sites.${chromosome}.vcf.bgz"
		output_path="${output_dir}/gnomad.genomes.v3.1.1.sites.${chromosome}.stripped.vcf.gz"
			
		if [[ ! -f "${output_path}" ]]; then
			${BCFTOOLS_CMD} filter --no-version -i "(filter==\"PASS\" || filter==\".\")" -Ou "${input_path}" | \
			${BCFTOOLS_CMD} annotate --no-version -x ID,QUAL,FILTER,^INFO/AF -Oz --threads "${THREADS}" -o "${output_path}"
			${BCFTOOLS_CMD} index "${output_path}"
		else
			echo "    skip stripping for '${chromosome}' because file already exists"
		fi

		output_files+=("${output_path}")		
		echo "  processing chromosome ${chromosome} done"
	done

	local -r total_output_path="${SCRIPT_DIR}/${ASSEMBLY}/gnomad.genomes.v3.1.1.sites.stripped.vcf.gz"
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
