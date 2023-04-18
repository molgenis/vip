#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-w <arg> -i <arg> -o <arg>]
  -w, --workflow          <arg>  workflow to execute. allowed values: cram, fastq, vcf
  -i, --input             <arg>  path to sample sheet .tsv
  -o, --output            <arg>  output folder
  -c, --config            <arg>  path to additional nextflow .cfg (optional)
  -p, --profile           <arg>  nextflow configuration profile (optional)
  -r, --resume                   resume execution using cached results (default: false)
  -h, --help                     print this message and exit"
}

validate() {
  local -r workflow="${1}"
  local -r input="${2}"
  local -r output="${3}"
  local -r config="${4}"
  local -r profile="${5}"
  local -r resume="${6}"
  
  if [[ -z "${workflow}" ]]; then
    >&2 echo -e "error: missing required -w / --workflow"
    usage
    exit 2
  fi
  if [[ ! "${workflow}" =~ cram|fastq|vcf ]]; then
    >&2 echo -e "error: workflow '${workflow}'. allowed values are [cram, fastq, vcf]"
    usage
    exit 2
  fi

  if [[ -z "${input}" ]]; then
    >&2 echo -e "error: missing required -i / --input"
    usage
    exit 2
  fi
  if [[ ! -f "${input}" ]]; then
    >&2 echo -e "error: input '${input}' does not exist"
    exit 2
  fi

  if [[ -z "${output}" ]]; then
    >&2 echo -e "error: missing required -o / --output"
    usage
    exit 2
  fi
  if [[ "${resume}" == "false" ]] && [[ -d "${output}" ]]; then
    >&2 echo -e "error: output '${output}' already exists. remove or use -r / --resume to resume execution"
    exit 2
  fi
  if [[ -n "${config}" ]] && [[ ! -f "${config}" ]]; then
    >&2 echo -e "error: config '${config}' does not exist"
    exit 2
  fi
}

execute_workflow() {
  local -r paramWorkflow="${1}"
  local -r paramInput="${2}"
  local -r paramOutput="${3}"
  local -r paramConfig="${4}"
  local -r paramProfile="${5}"
  local -r paramResume="${6}"

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
  args+=("-profile" "${paramProfile}")
  args+=("-with-report" "${paramOutput}/nxf_report.html")
  args+=("-with-timeline" "${paramOutput}/nxf_timeline.html")
  args+=("--input" "${paramInput}")
  args+=("--output" "${paramOutput}")
  if [[ "${paramResume}" == "true" ]]; then
    args+=("-resume")
  fi

  (cd "${paramOutput}" && APPTAINER_BIND="${APPTAINER_BIND-${envBind}}" APPTAINER_CACHEDIR="${envCacheDir}" NXF_VER="23.04.1" NXF_HOME="${envHome}" NXF_TEMP="${envTemp}" NXF_WORK="${envWork}" NXF_ENABLE_STRICT="${envStrict}" "${SCRIPT_DIR}/nextflow" "${args[@]}")
}

main() {
  local args=$(getopt -a -n pipeline -o w:i:o:c:p:rh --long workflow:,input:,output:,config:,profile:,resume,help -- "$@")
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
  local resume="false"

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
      if [[ "$2" = /* ]]; then input="$2"; else input="${PWD}/$2"; fi
      shift 2
      ;;
    -o | --output)
      if [[ "$2" = /* ]]; then output="$2"; else output="${PWD}/$2"; fi
      shift 2
      ;;
    -c | --config)
      if [[ "$2" = /* ]]; then config="$2"; else config="${PWD}/$2"; fi
      shift 2
      ;;
    -p | --profile)
      profile="$2"
      shift 2
      ;;
    -r | --resume)
      resume="true"
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

  validate "${workflow}" "${input}" "${output}" "${config}" "${profile}" "${resume}"

  if [[ "${resume}" == "true" ]] && ! [[ -d "${output}" ]]; then
    resume="false"
  fi
  if ! [[ -d "${output}" ]]; then
    mkdir -p "${output}"
  fi
  
  execute_workflow "${workflow}" "${input}" "${output}" "${config}" "${profile}" "${resume}"
}

main "${@}"
