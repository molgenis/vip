#!/bin/bash
set -euo pipefail

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
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

  if ! command -v apptainer &>/dev/null; then
    echo "error: 'apptainer' could not be found"
    exit 1
  fi

  if [ "$EUID" -ne 0 ]
    then echo "error: 'apptainer' requires to run as as root, use 'sudo build.sh' to run as root."
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

  local images=()
  images+=("build/alpine-3.15.0")
  images+=("build/openjdk-17")
  images+=("bcftools-1.14")
  images+=("annotsv-3.2.3")
  images+=("capice-5.0.0")
  images+=("minimap2-2.24")
  images+=("samtools-1.16")
  images+=("vcf-decision-tree-3.5.1")
  images+=("vcf-inheritance-matcher-2.1.4")
  images+=("vcf-report-5.1.5")
  
  for i in "${!images[@]}"; do
    echo "---Building ${images[$i]}---"
    apptainer build "${outputDir}/${images[$i]}.sif" "${inputDir}/${images[$i]}.def" | tee "${outputDir}/build.log"
    echo "---Done building ${images[$i]}---"
  done

  declare -A uris
  uris["docker://ensemblorg/ensembl-vep:release_107.0"]="vep-107.0"
  uris["docker://hkubal/clair3:latest"]="clair3-v0.1-r12"
  uris["docker://ghcr.io/dnanexus-rnd/glnexus:v1.4.1"]="glnexus_v1.4.1"
  
  for i in "${!uris[@]}"; do
    echo "---Building from URI ${i}---"
    apptainer build "${outputDir}/${uris[${i}]}.sif" "${i}" | tee "${outputDir}/build.log"
    echo "---Done building ${uris[${i}]}---"
  done
}

main "${@}"
