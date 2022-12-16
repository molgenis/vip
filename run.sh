#!/bin/bash
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-i <arg> -o <arg> -w <arg>]
  -w, --workflow <arg>  workflow to execute. allowed values: cram, fastq, gvcf, vcf
  -i, --input    <arg>  path to sample sheet .tsv
  -o, --output   <arg>  output folder
  -c, --config   <arg>  path to additional nextflow .cfg (optional)
  -h, --help            print this message and exit"
}

validate() {
  local -r workflow="${1}"
  local -r input="${2}"
  local -r output="${3}"
  local -r config="${4}"
  
  if [[ -z "${workflow}" ]]; then
    >&2 echo -e "error: missing required -w / --workflow"
    usage
    exit 2
  else
    if [[ ! "${workflow}" =~ cram|fastq|gvcf|vcf ]]; then
      >&2 echo -e "error: workflow '${workflow}'. allowed values are [cram, fastq, gvcf, vcf]"
      usage
      exit 2
    fi
  fi
  if [[ -z "${input}" ]]; then
    >&2 echo -e "error: missing required -i / --input"
    usage
    exit 2
  fi
  if [[ -z "${output}" ]]; then
    >&2 echo -e "error: missing required -o / --output"
    usage
    exit 2
  fi
}

execute_workflow() {
  local -r paramWorkflow="${1}"
  local -r paramInput="${2}"
  local -r paramOutput="${3}"
  local -r paramConfig="${4}"

  rm -f "${paramOutput}/nxf_report.html"
  rm -f "${paramOutput}/nxf_timeline.html"

  local configs="${SCRIPT_DIR}/config/nxf_${paramWorkflow}.config"
  if [[ -n "${paramConfig}" ]]; then
    configs+=",${paramConfig}"
  fi

  local binds=()
  binds+=("/$(realpath "${paramInput}" | cut -f 2 -d "/")")
  if [[ -n "${TMPDIR}" ]]; then
    binds+=("${TMPDIR}")
  elif [[ -d "/tmp" ]]; then
    binds+=("/tmp")
  fi

  APPTAINER_BIND="$(IFS=, ; echo "${binds[*]}")" \
  APPTAINER_CACHEDIR="${SCRIPT_DIR}/images" \
  NXF_HOME="${paramOutput}/.nxf.home" \
  NXF_TEMP="${paramOutput}/.nxf.tmp" \
  NXF_WORK="${paramOutput}/.nxf.work" \
  NXF_ENABLE_STRICT="true" \
  "${SCRIPT_DIR}/nextflow" -C "${configs[@]}" -log "${paramOutput}/.nxf.log" run "${SCRIPT_DIR}/vip_${paramWorkflow}.nf" \
    -offline \
    -resume \
    -profile cluster \
    -with-report "${paramOutput}/nxf_report.html" \
    -with-timeline "${paramOutput}/nxf_timeline.html" \
    --input "${paramInput}" \
    --output "${paramOutput}"
}

main() {
  local -r args=$(getopt -a -n pipeline -o w:i:o:c:h --long workflow:,input:,output:,config:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local workflow=""
  local input=""
  local output=""
  local config=""

  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      shift
      ;;
    -w | --workflow)
      workflow="$2"
      shift 2
      ;;
    -i | --input)
      input="$2"
      shift 2
      ;;
    -o | --output)
      output="$2"
      shift 2
      ;;
    -c | --config)
      config="$2"
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

  validate "${workflow}" "${input}" "${output}" "${config}"
  execute_workflow "${workflow}" "${input}" "${output}" "${config}"
}

main "${@}"
