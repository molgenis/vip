#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-a <arg>]
  -a, --assembly   <arg>    Allowed values: GRCh37, GRCh38, ALL (default).
  -h, --help                Print this message and exit."
}

validate() {
  local -r assembly="${1}"
  if [ "${assembly}" != "ALL" ] && [ "${assembly}" != "GRCh37" ] && [ "${assembly}" != "GRCh38" ]; then
    echo -e "invalid assembly value '${assembly}'. valid values are ALL, GRCh37, GRCh38."
    exit 1
  fi
}

download_nextflow() {
  local -r version="22.10.0"
  local -r file="nextflow-${version}-all"
  local -r download_dir="${SCRIPT_DIR}"

  if [ ! -f "${download_dir}/${file}" ]; then
      echo -e "downloading from download.molgeniscloud.org: ${file} ..."
      wget --quiet --continue "https://download.molgeniscloud.org/downloads/vip/nextflow/${file}" --output-document "${download_dir}/${file}"
      chmod +x "${download_dir}/${file}"
      (cd "${download_dir}" && ln -s ${file} "nextflow")
    else
      echo -e "skipping download ${download_dir}/${file}: already exists"
    fi
}

# FIXME re-enable all file downloads
download_resources_molgenis() {
  local -r assembly="${1}"

  local files=()
#  files+=("hpo_20220712.tsv")
#  files+=("inheritance_20220712.tsv")

  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh37" ]; then
#    files+=("GRCh37/capice_model_v4.0.0-v2.pickle.dat")
#    files+=("GRCh37/clinvar_20220620.vcf.gz")
#    files+=("GRCh37/clinvar_20220620.vcf.gz.tbi")
#    files+=("GRCh37/gnomad.total.r2.1.1.sites.stripped.vcf.gz")
#    files+=("GRCh37/gnomad.total.r2.1.1.sites.stripped.vcf.gz.csi")
#    files+=("GRCh37/hg19.100way.phyloP100way.bw")
    files+=("GRCh37/human_g1k_v37.dict")
    files+=("GRCh37/human_g1k_v37.fasta.gz")
    files+=("GRCh37/human_g1k_v37.fasta.gz.fai")
    files+=("GRCh37/human_g1k_v37.fasta.gz.gzi")
#    files+=("GRCh37/spliceai_scores.masked.indel.hg19.vcf.gz")
#    files+=("GRCh37/spliceai_scores.masked.indel.hg19.vcf.gz.tbi")
#    files+=("GRCh37/spliceai_scores.masked.snv.hg19.vcf.gz")
#    files+=("GRCh37/spliceai_scores.masked.snv.hg19.vcf.gz.tbi")
#    files+=("GRCh37/GCF_000001405.25_GRCh37.p13_genomic_g1k.gff.gz")
#    files+=("GRCh37/vkgl_consensus_20211201.tsv")
  fi

  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh38" ]; then
#    files+=("GRCh38/capice_model_v4.0.0-v2.pickle.dat")
#    files+=("GRCh38/clinvar_20220620.vcf.gz")
#    files+=("GRCh38/clinvar_20220620.vcf.gz.tbi")
#    files+=("GRCh38/gnomad.genomes.v3.1.2.sites.stripped.vcf.gz")
#    files+=("GRCh38/gnomad.genomes.v3.1.2.sites.stripped.vcf.gz.csi")
#    files+=("GRCh38/hg38.phyloP100way.bw")
#    files+=("GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz")
#    files+=("GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz.tbi")
#    files+=("GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz")
#    files+=("GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz.tbi")
#    files+=("GRCh38/GCF_000001405.39_GRCh38.p13_genomic_mapped.gff.gz")
#    files+=("GRCh38/vkgl_consensus_20211201.tsv")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.dict")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.fai")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.gzi")
  fi

  for file in "${files[@]}"; do
    if [ ! -f "${download_dir}/${file}" ]; then
      echo -e "downloading from download.molgeniscloud.org: ${file} ..."
      wget --quiet --continue "https://download.molgeniscloud.org/downloads/vip/resources/${file}" --output-document "${download_dir}/${file}"
    else
      echo -e "skipping download ${download_dir}/${file}: already exists"
    fi
  done
}

download_resources_vep() {
  local -r assembly="${1}"

  local -r vep_dir="${SCRIPT_DIR}/resources/vep/cache"

  mkdir -p "${vep_dir}"

  local vep_files=()
  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh37" ]; then
    if [ ! -d "${vep_dir}/homo_sapiens_refseq/107_GRCh37" ]; then
      vep_files+=("homo_sapiens_refseq_vep_107_GRCh37.tar.gz")
    else
      echo -e "skipping download vep cache for GRCh37: already exists"
    fi
  fi
  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh38" ]; then
    if [ ! -d "${vep_dir}/homo_sapiens_refseq/107_GRCh38" ]; then
      vep_files+=("homo_sapiens_refseq_vep_107_GRCh38.tar.gz")
    else
      echo -e "skipping download vep cache for GRCh38: already exists"
    fi
  fi

  if [ ${#vep_files[@]} != 0 ]; then
    for vep_file in "${vep_files[@]}"; do
      echo -e "downloading from ftp.ensembl.org: ${vep_file} ..."
      wget --quiet --continue "http://ftp.ensembl.org/pub/release-107/variation/indexed_vep_cache/${vep_file}" --output-document - | tar -xz -C "${vep_dir}"
    done
  fi
}

download_resources_annotsv() {
  local -r annotsv_dir="${SCRIPT_DIR}/resources/annotsv/v3.0.9"
  if [ ! -d "${annotsv_dir}" ]; then
    mkdir -p "${annotsv_dir}"
    # workaround for ERROR: cannot verify certificate: Issued certificate has expired
    echo -e "downloading from www.lbgi.fr: Annotations_Human_3.0.9.tar.gz ..."
    wget --quiet --continue --no-check-certificate "https://www.lbgi.fr/~geoffroy/Annotations/Annotations_Human_3.0.9.tar.gz" --output-document - | tar -xz -C "${annotsv_dir}"
  else
    echo -e "skipping download annotsv annotations: already exists"
  fi

  local -r annotsv_exomiser_dir="${annotsv_dir}/Annotations_Exomiser/2007"
  if [ ! -d "${annotsv_exomiser_dir}" ]; then
    mkdir -p "${annotsv_exomiser_dir}"
    # workaround for ERROR: cannot verify certificate: Issued certificate has expired
    echo -e "downloading from www.lbgi.fr: 2007_hg19.tar.gz ..."
    wget --quiet --continue --no-check-certificate "https://www.lbgi.fr/~geoffroy/Annotations/2007_hg19.tar.gz" --output-document - | tar -xz -C "${annotsv_exomiser_dir}"
    echo -e "downloading from data.monarchinitiative.org: 2007_phenotype.zip ..."
    wget --quiet --continue "https://data.monarchinitiative.org/exomiser/data/2007_phenotype.zip" --directory-prefix "${annotsv_exomiser_dir}"
    unzip -qq "${annotsv_exomiser_dir}/2007_phenotype.zip" -d "${annotsv_exomiser_dir}"
    rm "${annotsv_exomiser_dir}/2007_phenotype.zip"
  else
    echo -e "skipping download annotsv exomiser annotations: already exists"
  fi
}

# FIXME re-enable vep and annotsv downloads
download_resources() {
  local -r assembly="${1}"

  local -r download_dir="${SCRIPT_DIR}/resources"
  mkdir -p "${download_dir}"

  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh37" ]; then
    mkdir -p "${download_dir}/GRCh37"
  fi
  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh38" ]; then
    mkdir -p "${download_dir}/GRCh38"
  fi

  download_resources_molgenis "${assembly}"
#  download_resources_vep "${assembly}"
#  download_resources_annotsv
}

# FIXME re-enable image downloads
download_images() {
  local -r download_dir="${SCRIPT_DIR}/images"
  mkdir -p "${download_dir}"

  local files=()
#  files+=("annotsv-3.0.9.sif")
  files+=("bcftools-1.14.sif")
#  files+=("capice-4.0.0.sif")
#  files+=("gatk-4.2.5.0.sif")
  files+=("samtools-1.16.sif")
#  files+=("vcf-decision-tree-3.4.2.sif")
#  files+=("vcf-inheritance-matcher-2.1.2.sif")
#  files+=("vcf-report-5.1.0.sif")
#  files+=("vep-107.0.sif")

  for file in "${files[@]}"; do
    if [ ! -f "${download_dir}/${file}" ]; then
      echo -e "downloading from download.molgeniscloud.org: ${file} ..."
      wget --quiet --continue "https://download.molgeniscloud.org/downloads/vip/images/${file}" --output-document "${download_dir}/${file}"
    else
      echo -e "skipping download ${download_dir}/${file}: already exists"
    fi
  done
}

# FIXME remove before PR merge
download_images_dev() {
  local -r download_dir="${SCRIPT_DIR}/images"
  mkdir -p "${download_dir}"

  local files=()
  files+=("deepvariant_1.4.0.sif")
  files+=("deepvariant_deeptrio-1.4.0.sif")
  files+=("minimap2-2.24.sif")

  for file in "${files[@]}"; do
    if [ ! -f "${download_dir}/${file}" ]; then
      echo -e "downloading from download.molgeniscloud.org: ${file} ..."
      wget --quiet --continue "https://download.molgeniscloud.org/downloads/vip_dev/images/${file}" --output-document "${download_dir}/${file}"
    else
      echo -e "skipping download ${download_dir}/${file}: already exists"
    fi
  done
}

main() {
  local -r args=$(getopt -a -n pipeline -o a:h --long assembly:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local assembly="ALL"

  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      shift
      ;;
    -a | --assembly)
      assembly="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      exit 2
      ;;
    esac
  done

  validate "${assembly}"

  echo -e "installing ..."
  download_nextflow
  download_images
  download_images_dev
  download_resources "${assembly}"
  echo -e "installing done"
}

main "${@}"

