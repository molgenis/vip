#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")
SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} -f

-f, --force               optional: Override the output file if it already exists."
}

# arguments:
#   $1  output directory
#   $2  force
validate() {
  local -r outputDir="${1}"
  local -r force="${2}"

  if [[ "${force}" == "0" ]] && [[ -d "${outputDir}" ]]; then
    echo -e "error: output directory ${outputDir} already exists, use -f to overwrite."
    exit 1
  fi

  if ! command -v singularity &>/dev/null; then
    echo "error: 'singularity' could not be found"
    exit 1
  fi

  if [ "$EUID" -ne 0 ]
    then echo "error: 'singularity' requires to run as as root, use 'sudo build.sh' to run as root."
    exit
  fi
}

main() {
  local -r args=$(getopt -a -n pipeline -o i:o:b:p:t:c:fkh --long input:,output:,probands:,pedigree:,phenotypes:,config:,force,keep,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local -r inputDir="${SCRIPT_DIR}/def"
  local -r outputDir="${SCRIPT_DIR}/sif"
  local force=0

  eval set -- "$args"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      shift
      ;;
    -f | --force)
      force=1
      shift
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

  validate "${outputDir}" "${force}"

  if [[ -d "${outputDir}" ]] && [[ "${force}" == "1" ]]; then
    rm -rf "${outputDir}"
  fi
  mkdir -p "${outputDir}"
  mkdir -p "${outputDir}/build"

  images=()
  images+=("build/alpine-3.15.0")
  images+=("build/openjdk-17")
  images+=("bcftools-1.14")
  images+=("samtools-1.16")
  images+=("gatk-4.2.5.0" "vcf-decision-tree-3.3.1" "vcf-inheritance-matcher-2.1.2" "vcf-report-5.0.0")
  images+=("annotsv-3.0.9")
  images+=("capice-3.2.0")

  for i in "${!images[@]}"; do
    echo "---Building ${images[$i]}---"
    singularity build "${outputDir}/${images[$i]}.sif" "${inputDir}/${images[$i]}.def" | tee "${outputDir}/build.log"
    echo "---Done building ${images[$i]}---"
  done

  echo "---Building vep-107.0---"
  singularity build "${outputDir}/vep-107.0.sif" docker://ensemblorg/ensembl-vep:release_107.0 | tee "${outputDir}/build.log"
  echo "---Done building vep-107.0---"
}

main "${@}"
