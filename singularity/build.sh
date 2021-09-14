#!/bin/bash

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
  images+=("build/alpine-scratch")
  images+=("build/alpine-build")
  images+=("build/OpenJDK")
  images+=("build/Python")
  images+=("HTSlib" "BCFtools")
  images+=("GATK" "vcf-decision-tree" "vcf-inheritance-matcher" "vcf-report" "VIBE")
  images+=("Genmod")
  images+=("vcfanno")
  images+=("AnnotSV")
  images+=("VEP")

  for i in "${!images[@]}"; do
    echo "---Building ${images[$i]}---"
    singularity build "${outputDir}/${images[$i]}.sif" "${inputDir}/${images[$i]}.def" | tee "${outputDir}/build.log"
    echo "---Done building ${images[$i]}---"
  done
}

main "${@}"
