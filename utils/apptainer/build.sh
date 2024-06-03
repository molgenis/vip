#!/bin/bash
set -eo pipefail

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"
set -u

usage() {
  echo -e "usage: ${SCRIPT_NAME} -f

-f, --force               optional: Override the output file if it already exists.

note: user must be allowed to run 'sudo apptainer build'."
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
}

main() {
  local args=$(getopt -a -n pipeline -o i:o:b:p:t:c:fkh --long input:,output:,probands:,pedigree:,phenotypes:,config:,force,keep,help -- "$@")
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
  images+=("build/alpine-3.18.3")
  images+=("build/openjdk-17")
  images+=("build/ubuntu-22.04")
  images+=("bcftools-1.17")
  images+=("annotsv-3.3.6")
  images+=("capice-5.1.2")
  images+=("cutesv-2.1.1")
  images+=("expansionhunter-5.0.0")
  images+=("fastp-0.23.4")
  #see ./def/glnexus_v1.4.5-patched.txt
  #images+=("glnexus_v1.4.5-patched")
  images+=("gado-1.0.3")
  images+=("manta-1.6.0")
  images+=("minimap2-2.27")
  images+=("picard-3.1.1")
  images+=("samtools-1.17-patch1")
  images+=("stranger-0.8.1")
  images+=("straglr-1.5.0")
  images+=("vcf-decision-tree-4.1.1")
  images+=("vcf-inheritance-matcher-3.1.0")
  images+=("vcf-report-6.0.2")

  for i in "${!images[@]}"; do
    echo "---Building ${images[$i]}---"
    (cd "${SCRIPT_DIR}" && sudo apptainer build "${outputDir}/${images[$i]}.sif" "${inputDir}/${images[$i]}.def" | tee "${outputDir}/build.log")
    echo "---Done building ${images[$i]}---"
  done

  declare -A uris
  uris["docker://ensemblorg/ensembl-vep:release_111.0"]="vep-111.0"
  uris["docker://google/deepvariant:1.6.0"]="deepvariant-1.6.0"
  uris["docker://google/deepvariant:deeptrio-1.6.0"]="deepvariant_deeptrio-1.6.0"
  
  for i in "${!uris[@]}"; do
    echo "---Building from URI ${i}---"
    (cd "${SCRIPT_DIR}" && sudo apptainer build "${outputDir}/${uris[${i}]}.sif" "${i}" | tee "${outputDir}/build.log")
    echo "---Done building ${uris[${i}]}---"
  done
}

main "${@}"
