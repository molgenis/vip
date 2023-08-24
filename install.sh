#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

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

download() {
  local -r url="${1}"
  local -r output="${2}"

  if [ ! -f "${output}" ]; then
    echo -e "downloading ${url} ..."
    if ! wget --quiet --continue "${url}" --output-document "${output}"; then
      echo -e "an error occurred downloading ${url}"
        # wget always writes an (empty) output file regardless of errors
        rm -f "${output}"
        exit 1
    fi
  else
    echo -e "skipping download: ${output} already exists"
  fi
}

download_nextflow() {
  local -r version="23.04.1"
  local -r file="nextflow-${version}-all"
  local -r download_dir="${SCRIPT_DIR}"

  download "https://download.molgeniscloud.org/downloads/vip/nextflow/${file}" "${download_dir}/${file}"
  (cd "${download_dir}" && chmod +x "${file}" && rm -f nextflow && ln -s ${file} "nextflow")
}

download_resources_molgenis() {
  local -r assembly="${1}"

  local files=()
  files+=("hpo_20230608.tsv")
  files+=("inheritance_20230608.tsv")

  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh37" ]; then
    files+=("GRCh37/capice_model_v5.1.1-v1.ubj")
    files+=("GRCh37/clinvar_20230604.vcf.gz")
    files+=("GRCh37/clinvar_20230604.vcf.gz.tbi")
    files+=("GRCh37/expansionhunter_variant_catalog.json")
    files+=("GRCh37/GCF_000001405.25_GRCh37.p13_genomic_g1k.gff.gz")
    files+=("GRCh37/gnomad.total.r2.1.1.sites.stripped.patch1.vcf.gz")
    files+=("GRCh37/gnomad.total.r2.1.1.sites.stripped.patch1.vcf.gz.csi")
    # workaround for https://github.com/Ensembl/ensembl-vep/issues/1414
    files+=("GRCh37/hg19.100way.phyloP100way.bed.gz")
    files+=("GRCh37/hg19.100way.phyloP100way.bed.gz.tbi")
    files+=("GRCh37/human_g1k_v37.dict")
    #FIXME: remove line below after clair 3 is fixed
    files+=("GRCh37/human_g1k_v37.fasta.fai")
    files+=("GRCh37/human_g1k_v37.fasta.gz")
    files+=("GRCh37/human_g1k_v37.fasta.gz.fai")
    files+=("GRCh37/human_g1k_v37.fasta.gz.gzi")
    files+=("GRCh37/human_g1k_v37.fasta.gz.mmi")
    files+=("GRCh37/spliceai_scores.masked.indel.hg19.vcf.gz")
    files+=("GRCh37/spliceai_scores.masked.indel.hg19.vcf.gz.tbi")
    files+=("GRCh37/spliceai_scores.masked.snv.hg19.vcf.gz")
    files+=("GRCh37/spliceai_scores.masked.snv.hg19.vcf.gz.tbi")
    files+=("GRCh37/uORF_5UTR_PUBLIC.txt")
    files+=("GRCh37/vkgl_consensus_20230401.tsv")
    files+=("GRCh37/human_hs37d5.trf.bed")
  fi

  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh38" ]; then
    files+=("GRCh38/capice_model_v5.1.1-v1.ubj")
    files+=("GRCh38/clinvar_20230604.vcf.gz")
    files+=("GRCh38/clinvar_20230604.vcf.gz.tbi")
    files+=("GRCh38/expansionhunter_variant_catalog.json")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.dict")
    #FIXME: remove line below after clair 3 is fixed
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.fai")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.gzi")
    files+=("GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.mmi")
    files+=("GRCh38/GCF_000001405.39_GRCh38.p13_genomic_mapped.gff.gz")
    files+=("GRCh38/gnomad.genomes.v3.1.2.sites.stripped.vcf.gz")
    files+=("GRCh38/gnomad.genomes.v3.1.2.sites.stripped.vcf.gz.csi")
    # workaround for https://github.com/Ensembl/ensembl-vep/issues/1414
    files+=("GRCh38/hg38.phyloP100way.bed.gz")
    files+=("GRCh38/hg38.phyloP100way.bed.gz.tbi")
    files+=("GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz")
    files+=("GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz.tbi")
    files+=("GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz")
    files+=("GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz.tbi")
    files+=("GRCh38/uORF_5UTR_PUBLIC.txt")
    files+=("GRCh38/vkgl_consensus_20230401.tsv")
    files+=("GRCh38/human_GRCh38_no_alt_analysis_set.trf.bed")
  fi

  for file in "${files[@]}"; do
    download "https://download.molgeniscloud.org/downloads/vip/resources/${file}" "${download_dir}/${file}"
  done
}

download_resources_vep() {
  local -r assembly="${1}"

  local -r vep_dir="${SCRIPT_DIR}/resources/vep/cache"

  mkdir -p "${vep_dir}"

  local vep_files=()
  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh37" ]; then
    if [ ! -d "${vep_dir}/homo_sapiens_refseq/109_GRCh37" ]; then
      vep_files+=("homo_sapiens_refseq_vep_109_GRCh37.tar.gz")
    else
      echo -e "skipping download vep cache for GRCh37: already exists"
    fi
  fi
  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh38" ]; then
    if [ ! -d "${vep_dir}/homo_sapiens_refseq/109_GRCh38" ]; then
      vep_files+=("homo_sapiens_refseq_vep_109_GRCh38.tar.gz")
    else
      echo -e "skipping download vep cache for GRCh38: already exists"
    fi
  fi

  if [ ${#vep_files[@]} != 0 ]; then
    for vep_file in "${vep_files[@]}"; do
      echo -e "downloading from ftp.ensembl.org: ${vep_file} ..."
      wget --quiet --continue "http://ftp.ensembl.org/pub/release-109/variation/indexed_vep_cache/${vep_file}" --output-document - | tar -xz -C "${vep_dir}"
    done
  fi
}

download_resources_annotsv() {
  local -r annotsv_dir="${SCRIPT_DIR}/resources/annotsv/v3.3.6"
  if [ ! -d "${annotsv_dir}" ]; then
    mkdir -p "${annotsv_dir}"
    echo -e "downloading from www.lbgi.fr: Annotations_Human_3.3.6.tar.gz ..."
    wget --quiet --continue "https://www.lbgi.fr/~geoffroy/Annotations/Annotations_Human_3.3.6.tar.gz" --output-document - | tar -xz -C "${annotsv_dir}"
  else
    echo -e "skipping download annotsv annotations: already exists"
  fi

  local -r annotsv_exomiser_dir="${annotsv_dir}/Annotations_Exomiser/2202"
  if [ ! -d "${annotsv_exomiser_dir}" ]; then
    mkdir -p "${annotsv_exomiser_dir}"
    # workaround for ERROR: cannot verify certificate: Issued certificate has expired
    echo -e "downloading from www.lbgi.fr: 2202_hg19.tar.gz ..."
    wget --quiet --continue --no-check-certificate "https://www.lbgi.fr/~geoffroy/Annotations/2202_hg19.tar.gz" --output-document - | tar -xz -C "${annotsv_exomiser_dir}"
    echo -e "downloading from data.monarchinitiative.org: 2202_phenotype.zip ..."
    wget --quiet --continue "https://data.monarchinitiative.org/exomiser/data/2202_phenotype.zip" --directory-prefix "${annotsv_exomiser_dir}"
    unzip -qq "${annotsv_exomiser_dir}/2202_phenotype.zip" -d "${annotsv_exomiser_dir}"
    rm "${annotsv_exomiser_dir}/2202_phenotype.zip"
  else
    echo -e "skipping download annotsv exomiser annotations: already exists"
  fi
}

download_resources_gado() {
  local -r gado_dir="${SCRIPT_DIR}/resources/gado/v1.0.3"
    if [ ! -d "${gado_dir}" ]; then
      mkdir -p "${gado_dir}"

      local files=()
      
      files+=("HPO_2023_06_17_predictions.cols.txt.gz")
      files+=("HPO_2023_06_17_predictions.datg")
      files+=("HPO_2023_06_17_predictions.rows.txt.gz")
      files+=("hp.obo")
      files+=("genes.txt")
      files+=("HPO_2023_06_17_predictions_auc_bonf.txt.gz")

      for file in "${files[@]}"; do
        download "https://download.molgeniscloud.org/downloads/vip/resources/gado/v1.0.3/${file}" "${gado_dir}/${file}"
      done
    else
      echo -e "skipping download gado resources: already exists"
    fi
}

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
  download_resources_vep "${assembly}"
  download_resources_annotsv
  download_resources_gado
}

download_images() {
  local -r download_dir="${SCRIPT_DIR}/images"
  mkdir -p "${download_dir}"

  local files=()
  files+=("annotsv-3.3.6.sif")
  files+=("bcftools-1.17.sif")
  files+=("capice-5.1.1.sif")
  files+=("clair3-v1.0.2.sif")
  files+=("cutesv-2.0.3.sif")
  files+=("expansionhunter-5.0.0.sif")
  files+=("glnexus_v1.4.5-patched.sif")
  files+=("minimap2-2.24.sif")
  files+=("samtools-1.17-patch1.sif")
  files+=("vcf-decision-tree-3.5.4.sif")
  files+=("vcf-inheritance-matcher-2.1.6.sif")
  files+=("vcf-report-5.5.2.sif")
  files+=("vep-109.3.sif")
  files+=("manta-1.6.0.sif")
  files+=("gado-1.0.3.sif")

  for file in "${files[@]}"; do
    download "https://download.molgeniscloud.org/downloads/vip/images/${file}" "${download_dir}/${file}"
  done
}

create_executable() {
  chmod +x "${SCRIPT_DIR}/vip.sh"
  if [ ! -f "${SCRIPT_DIR}/vip" ]; then
    (cd "${SCRIPT_DIR}" && ln -s "vip.sh" "vip")
  fi
}

unzip_reference() {
  local -r assembly="${1}"
  local -r download_dir="${SCRIPT_DIR}/resources"

  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh37" ]; then
    if [ ! -f "${download_dir}/GRCh37/human_g1k_v37.fasta" ]; then
      gunzip -c "${download_dir}/GRCh37/human_g1k_v37.fasta.gz" > "${download_dir}/GRCh37/human_g1k_v37.fasta"
    else
      echo -e "skipping extraction of reference for GRCh37: already exists"
    fi
  fi
  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh38" ]; then
    if [ ! -f "${download_dir}/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna" ]; then
      gunzip -c "${download_dir}/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz" > "${download_dir}/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
    else
      echo -e "skipping extraction of reference for GRCh38: already exists"
    fi
  fi
}

main() {
  local args=$(getopt -a -n pipeline -o a:h --long assembly:,help -- "$@")
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
  download_resources "${assembly}"
  #FIXME: remove after clair 3 is fixed
  unzip_reference "${assembly}"
  create_executable
  echo -e "installing done"
}

main "${@}"

