#!/bin/bash
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

#FIXME currently input is treated as .vcf.gz
usage() {
  echo -e "usage: ${SCRIPT_NAME} [-i <arg> -o <arg>]
  -i, --input  <arg>  absolute path to .vcf.gz
  -o, --output <arg>  output folder
  -h, --help          Print this message and exit"
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

  rm -f "${paramOutput}/nxf_report.html"
  rm -f "${paramOutput}/nxf_timeline.html"

  APPTAINER_BIND="/groups,/tmp" \
  APPTAINER_CACHEDIR="${SCRIPT_DIR}/images" \
  NXF_HOME="${paramOutput}/.nxf.home" \
  NXF_TEMP="${paramOutput}/.nxf.tmp" \
  NXF_WORK="${paramOutput}/.nxf.work" \
  NXF_ENABLE_STRICT="true" \
  "${SCRIPT_DIR}/nextflow" -C "${SCRIPT_DIR}/config/nxf_vcf.config" -log "${paramOutput}/.nxf.log" run "${SCRIPT_DIR}/vip_vcf.nf" \
    -offline \
    -resume \
    -profile cluster \
    -with-report "${paramOutput}/nxf_report.html" \
    -with-timeline "${paramOutput}/nxf_timeline.html" \
    --input "${paramInput}" \
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
