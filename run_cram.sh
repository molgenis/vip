#!/bin/bash
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-i <arg> -o <arg>]
  -i, --input  <arg>  sample sheet .csv
  -o, --output <arg>  output folder
  -h, --help          Print this message and exit
  
sample sheet:
  family_id      required
  individual_id  required
  paternal_id    optional
  maternal_id    optional
  proband        optional. valid values: true, false
  hpo_terms      optional. valid values: semi-colon separated HPO terms
  cram           required. valid values: absolute path to .cram"
}

validate() {
  local -r input="${1}"
  local -r output="${2}"
  
  if [[ -z "${input}" ]]; then
    echo -e "error: missing required -i / --input"
    usage
    exit 2
  fi
  if [[ -z "${output}" ]]; then
    echo -e "error: missing required -o / --output"
    usage
    exit 2
  fi
}

execute_workflow() {
  local -r paramInput="${1}"
  local -r paramOutput="${2}"

  rm -f "${paramOutput}/report.html"
  rm -f "${paramOutput}/timeline.html"

  SINGULARITY_BIND="/groups,/tmp" \
  SINGULARITY_CACHEDIR="${SCRIPT_DIR}/images" \
  NXF_HOME="${paramOutput}/.nxf.home" \
  NXF_TEMP="${paramOutput}/.nxf.tmp" \
  NXF_WORK="${paramOutput}/.nxf.work" \
  "${SCRIPT_DIR}/nextflow" -C "${SCRIPT_DIR}/nxf_cram.config" -log "${paramOutput}/.nxf.log" run "${SCRIPT_DIR}/subworkflows/vip_cram.nf" \
    -offline \
    -resume \
    -profile cluster \
    -with-report "${paramOutput}/report.html" \
    -with-timeline "${paramOutput}/timeline.html" \
    --input "${paramInput}" \
    --reference "${SCRIPT_DIR}/resources/GRCh38/GCA_000001405.15_GRCh38_full_plus_hs38d1_analysis_set.fna.gz" \
    --output "${paramOutput}"
}

main() {
  local -r args=$(getopt -a -n pipeline -o i:o:h --long input:,output:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local input=""
  local output=""

  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      shift
      ;;
    -i | --input)
      input="$2"
      shift 2
      ;;
    -o | --output)
      output="$2"
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

  validate "${input}" "${output}"
  execute_workflow "${input}" "${output}"
}

main "${@}"
