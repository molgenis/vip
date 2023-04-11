#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-i <arg>]
  -i, --input <arg>  path to omim genemap2 file

  If no parameters are provided the inheritance file is created without OMIM."
}

createDummyGenemap() {
  echo "create dummy ${geneMapFilePath}"
  cat >"${geneMapFilePath}" <<EOT
# header line 1
# header line 2
# header line 3
# Chromosome	Genomic	Position	Start	Genomic	Position	End	Cyto	Location	Computed	Cyto	Location	MIM Number	Gene Symbols	Gene Name	Approved Symbol	Entrez Gene ID	Ensembl Gene ID	Comments	Phenotypes	Mouse Gene Symbol/ID
EOT
  echo "create dummy ${geneMapFilePath} done"
}

main() {
  local args=$(getopt -a -n pipeline -o i:h --long input_omim:,help -- "$@")

  local geneMapFilePath
  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -i | --input_omim)
      geneMapFilePath="${2}"
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

  echo -e "downloading ..."
  wget --quiet --continue https://download.molgeniscloud.org/downloads/vip/images/utils/vcf-inheritance-3.1.0.sif
  wget --quiet --continue https://download.molgeniscloud.org/downloads/vip/resources/utils/incomplete_penetrantie_genes_entrez_20210125.tsv
  wget --quiet --continue http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa
  wget --quiet --continue https://research.nhgri.nih.gov/CGD/download/txt/CGD.txt.gz
  echo -e "downloading done"

  # create dummy genemap2.txt if not provided
  if [ -z "${geneMapFilePath}" ]; then
    geneMapFilePath="genemap2.txt"
    createDummyGenemap "${geneMapFilePath}"
  else
    echo "genemap2 file provided, skipping dummy file creation."
  fi

  local outputPath="inheritance_$(date '+%Y%m%d').tsv"

  local args=()
  args+=("-jar" "/opt/vcf-inheritance/lib/genemap-mapper.jar")
  args+=("-i" "${geneMapFilePath}")
  args+=("-h" "phenotype.hpoa")
  args+=("--incomplete_penetrance" "incomplete_penetrantie_genes_entrez_20210125.tsv")
  args+=("-c" "CGD.txt.gz")
  args+=("-o" "${outputPath}")
  args+=("-f")

  echo -e "creating ${outputPath} ..."
  apptainer exec vcf-inheritance-3.1.0.sif java "${args[@]}"
  echo -e "creating ${outputPath} done"
}

main "${@}"
