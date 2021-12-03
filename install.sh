#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")

download_resources_molgenis () {
  local files=()
  files+=("hpo_20210920.tsv")
  files+=("inheritance_20211119.tsv")
  files+=("GRCh37/gnomad.total.r2.1.1.sites.stripped.vcf.gz")
  files+=("GRCh37/gnomad.total.r2.1.1.sites.stripped.vcf.gz.csi")
  files+=("GRCh37/human_g1k_v37.dict")
  files+=("GRCh37/human_g1k_v37.fasta.gz")
  files+=("GRCh37/human_g1k_v37.fasta.gz.fai")
  files+=("GRCh37/human_g1k_v37.fasta.gz.gzi")
  files+=("GRCh37/ucsc_genes_ncbi_refseq_20210519.txt.gz")
  files+=("GRCh37/vkgl_public_consensus_sep2021.tsv")
  files+=("GRCh38/gnomad.genomes.v3.1.1.sites.stripped.vcf.gz")
  files+=("GRCh38/gnomad.genomes.v3.1.1.sites.stripped.vcf.gz.csi")
  files+=("GRCh38/ucsc_genes_ncbi_refseq_20210519.txt.gz")
  files+=("GRCh38/vkgl_public_consensus_sep2021.tsv")
  files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.dict")
  files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz")
  files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.fai")
  files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.gzi")
  for file in "${files[@]}"; do
    if [ ! -f "${download_dir}/${file}" ]; then
      echo -e "downloading from download.molgeniscloud.org: ${file} ..."
      wget --quiet --continue "https://download.molgeniscloud.org/downloads/vip/resources/${file}" --output-document "${download_dir}/${file}"
    else
      echo -e "skipping download ${download_dir}/${file}: already exists"
    fi
  done
}

download_resources_vep () {
  local -r vep_dir="${SCRIPT_DIR}/resources/vep/cache"
  if [ ! -d "${vep_dir}" ]; then
    mkdir -p "${vep_dir}"

    local vep_files=()
    vep_files+=("homo_sapiens_refseq_vep_104_GRCh37.tar.gz")
    vep_files+=("homo_sapiens_refseq_vep_104_GRCh38.tar.gz")

    for vep_file in "${vep_files[@]}"; do
      echo -e "downloading from ftp.ensembl.org: ${vep_file} ..."
      wget --quiet --continue "http://ftp.ensembl.org/pub/release-104/variation/indexed_vep_cache/${vep_file}" --output-document - | tar -xz -C "${vep_dir}"
    done
  else
    echo -e "skipping download vep cache: already exists"
  fi
}

download_resources_annotsv () {
  local -r annotsv_dir="${SCRIPT_DIR}/resources/annotsv"
  if [ ! -d "${annotsv_dir}" ]; then
    mkdir -p "${annotsv_dir}"
    # workaround for ERROR: cannot verify certificate: Issued certificate has expired
    wget --quiet --continue --no-check-certificate "https://www.lbgi.fr/~geoffroy/Annotations/Annotations_Human_3.0.9.tar.gz" --output-document - | tar -xz -C "${annotsv_dir}"
  else
    echo -e "skipping download annotsv annotations: already exists"
  fi

  local -r annotsv_exomiser_dir="${annotsv_dir}/Annotations_Exomiser/2007"
  if [ ! -d "${annotsv_exomiser_dir}" ]; then
    mkdir -p "${annotsv_exomiser_dir}"
    # workaround for ERROR: cannot verify certificate: Issued certificate has expired
    wget --quiet --continue --no-check-certificate "https://www.lbgi.fr/~geoffroy/Annotations/2007_hg19.tar.gz" --output-document - | tar -xz -C "${annotsv_exomiser_dir}"
    wget --quiet --continue "https://data.monarchinitiative.org/exomiser/data/2007_phenotype.zip" --directory-prefix "${annotsv_exomiser_dir}"
    unzip -qq "${annotsv_exomiser_dir}/2007_phenotype.zip" -d "${annotsv_exomiser_dir}"
    rm "${annotsv_exomiser_dir}/2007_phenotype.zip"
  else
    echo -e "skipping download annotsv exomiser annotations: already exists"
  fi
}

download_resources () {
  local -r download_dir="${SCRIPT_DIR}/resources"
  mkdir -p "${download_dir}"
  mkdir -p "${download_dir}/GRCh37"
  mkdir -p "${download_dir}/GRCh38"

  download_resources_molgenis
  download_resources_vep
  download_resources_annotsv
}

download_images () {
  local -r download_dir="${SCRIPT_DIR}/images"
  mkdir -p "${download_dir}"

  local files=()
  files+=("annotsv-3.0.9.sif")
  files+=("bcftools-1.14.sif")
  files+=("gatk-4.2.2.0.sif")
  files+=("vcf-decision-tree-1.0.0.sif")
  files+=("vcf-inheritance-matcher-1.0.0.sif")
  files+=("vcf-report-2.5.2.sif")
  files+=("vep-104.3.sif")

  for file in "${files[@]}"; do
    if [ ! -f "${download_dir}/${file}" ]; then
      echo -e "downloading from download.molgeniscloud.org: ${file} ..."
      wget --quiet --continue "https://download.molgeniscloud.org/downloads/vip/images/${file}" --output-document "${download_dir}/${file}"
    else
      echo -e "skipping download ${download_dir}/${file}: already exists"
    fi
  done
}

main () {
  download_images
  download_resources
}

main "${@}"
