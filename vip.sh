#!/bin/bash
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-w <arg> -i <arg> -o <arg>]
  -w, --workflow          <arg>  workflow to execute. allowed values: cram, fastq, vcf
  -i, --input             <arg>  path to sample sheet .tsv
  -o, --output            <arg>  output folder
  -c, --config            <arg>  path to additional nextflow .cfg (optional)
  -p, --profile           <arg>  nextflow configuration profile (optional)
  -h, --help                     print this message and exit"
}

validate() {
  local -r workflow="${1}"
  local -r input="${2}"
  local -r output="${3}"
  local -r config="${4}"
  local -r profile="${5}"
  
  if [[ -z "${workflow}" ]]; then
    >&2 echo -e "error: missing required -w / --workflow"
    usage
    exit 2
  else
    if [[ ! "${workflow}" =~ cram|fastq|vcf ]]; then
      >&2 echo -e "error: workflow '${workflow}'. allowed values are [cram, fastq, vcf]"
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
  if [[ -n "${config}" ]] && [[ ! -f "${config}" ]]; then
    >&2 echo -e "error: config '${config}' does not exist"
  fi
}

execute_workflow() {
  local -r paramWorkflow="${1}"
  local -r paramInput="${2}"
  local -r paramOutput="${3}"
  local -r paramConfig="${4}"
  local -r paramProfile="${5}"

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

  local envBind="$(IFS=, ; echo "${binds[*]}")"
  local envCacheDir="${SCRIPT_DIR}/images"
  local envHome="${paramOutput}/.nxf.home"
  local envTemp="${paramOutput}/.nxf.tmp"
  local envWork="${paramOutput}/.nxf.work"
  local envStrict="true"

  local args=()
  args+=("-C" "${configs}")
  args+=("-log" "${paramOutput}/.nxf.log")
  args+=("run")
  args+=("${SCRIPT_DIR}/vip_${paramWorkflow}.nf")
  args+=("-offline")
  args+=("-resume")
  args+=("-profile" "${paramProfile}")
  args+=("-with-report" "${paramOutput}/nxf_report.html")
  args+=("-with-timeline" "${paramOutput}/nxf_timeline.html")
  args+=("--input" "${paramInput}")
  args+=("--output" "${paramOutput}")

  APPTAINER_BIND="${APPTAINER_BIND-${envBind}}" APPTAINER_CACHEDIR="${envCacheDir}" NXF_VER="22.10.6" NXF_HOME="${paramOutput}/.nxf.home" NXF_TEMP="${envTemp}" NXF_WORK="${envWork}" NXF_ENABLE_STRICT="${envStrict}" "${SCRIPT_DIR}/nextflow" "${args[@]}"
}

main() {
  local -r args=$(getopt -a -n pipeline -o w:i:o:c:p:h --long workflow:,input:,output:,config:,profile:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local workflow=""
  local input=""
  local output=""
  local config=""
  local profile=""
  if command -v sbatch &> /dev/null; then
    profile="slurm"
  else
    profile="local"
  fi

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
    -p | --profile)
      profile="$2"
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

  validate "${workflow}" "${input}" "${output}" "${config}" "${profile}"
  execute_workflow "${workflow}" "${input}" "${output}" "${config}" "${profile}"
}

main "${@}"
