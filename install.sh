#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")

download_resources () {
  local -r download_dir="${SCRIPT_DIR}/resources/"
  mkdir -p "${download_dir}"
  mkdir -p "${download_dir}/GRCh37"
  mkdir -p "${download_dir}/GRCh38"

  local files=()
  files+=("hpo_20210920.tsv")
  files+=("inheritance_20210920.tsv")
  files+=("GRCh37/gnomad.total.r2.1.1.sites.stripped.vcf.gz")
  files+=("GRCh37/gnomad.total.r2.1.1.sites.stripped.vcf.gz.csi")
  files+=("GRCh37/ucsc_genes_ncbi_refseq_20210519.txt.gz")
  files+=("GRCh38/gnomad.genomes.v3.1.1.sites.stripped.vcf.gz")
  files+=("GRCh38/gnomad.genomes.v3.1.1.sites.stripped.vcf.gz.csi")
  files+=("GRCh38/ucsc_genes_ncbi_refseq_20210519.txt.gz")

  for file in "${files[@]}"; do
    curl --silent --output "${download_dir}/${file}" "https://download.molgeniscloud.org/downloads/vip/resources/${file}"
  done
}

download_images () {
  local -r download_dir="${SCRIPT_DIR}/images"
  mkdir -p "${download_dir}"

  local files=()
  files+=("annotsv-3.0.9.sif")
  files+=("bcftools-1.13.sif")
  files+=("gatk-4.2.2.0.sif")
  files+=("vcf-decision-tree-1.0.0.sif")
  files+=("vcf-inheritance-matcher-1.0.0-alpha.sif")
  files+=("vcf-report-2.4.4.sif")
  files+=("vep-104.3.sif")

  for file in "${files[@]}"; do
    curl --silent --output "${download_dir}/${file}" "https://download.molgeniscloud.org/downloads/vip/images/${file}"
  done
}
main () {
  download_images
  download_resources
}

main "${@}"
