#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

# SCRIPT_DIR is incorrect when vip.sh is submitted as a Slurm job that is submitted as part of another Slurm job
VIP_DIR="${VIP_DIR:-"${SCRIPT_DIR}"}"
VIP_DIR_DATA="${VIP_DIR_DATA:-"${VIP_DIR}/../data"}"
VIP_VERSION="8.3.0"

display_version() {
  echo -e "${VIP_VERSION}"
}

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-w <arg> -i <arg> -o <arg>]
  -w, --workflow          <arg>  workflow to execute. allowed values: cram, fastq, gvcf, vcf
  -i, --input             <arg>  path to sample sheet .tsv
  -o, --output            <arg>  output folder
  -c, --config            <arg>  path to additional nextflow .cfg (optional)
  -p, --profile           <arg>  nextflow configuration profile (optional)
  -r, --resume                   resume execution using cached results (default: false)
  -s, --stub                     quickly prototype workflow logic using process script stubs
  -h, --help                     display this help and exit
  -v, --version                  display version information and exit
For complete documentation, visit <https://molgenis.github.io/vip/>"
}

validate() {
  local -r workflow="${1}"
  local -r input="${2}"
  local -r output="${3}"
  local -r config="${4}"
  local -r profile="${5}"
  local -r resume="${6}"
  local -r stub="${7}"
  
  if [[ -z "${workflow}" ]]; then
    >&2 echo -e "error: missing required -w / --workflow"
    usage
    exit 2
  fi
  if [[ ! "${workflow}" =~ cram|fastq|gvcf|vcf ]]; then
    >&2 echo -e "error: workflow '${workflow}'. allowed values are [cram, fastq, gvcf, vcf]"
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
  if [[ "${resume}" == "false" ]] && [[ -d "${output}" ]] && [[ $(find "${output}" -mindepth 1 -maxdepth 1 | read) ]]; then
    >&2 echo -e "error: output '${output}' already exists. remove or use -r / --resume to resume execution"
    exit 2
  fi
  if [[ -n "${config}" ]] && [[ ! -f "${config}" ]]; then
    >&2 echo -e "error: config '${config}' does not exist"
    exit 2
  fi

  # detect java, try to load module with name 'java' or 'Java' otherwise
  if ! command -v java &> /dev/null; then
    if command -v module &> /dev/null; then
      if module is_avail java; then
        module load java
      elif module is_avail Java; then
        module load Java
      else
        >&2 echo -e "error: missing required 'java'. could not find a module with name 'java' or 'Java' to load"
        exit 2
      fi
    else
      >&2 echo -e "error: missing required 'java'"
      exit 2
    fi
  fi
}

execute_workflow() {
  local -r paramWorkflow="${1}"
  local -r paramInput="${2}"
  local -r paramOutput="${3}"
  local -r paramConfig="${4}"
  local -r paramProfile="${5}"
  local -r paramResume="${6}"
  local -r paramStub="${7}"

  rm -f "${paramOutput}/nxf_report.html"
  rm -f "${paramOutput}/nxf_timeline.html"

  local configs="${VIP_DIR}/config/nxf_${paramWorkflow}.config"
  if [[ -n "${paramConfig}" ]]; then
    configs+=",${paramConfig}"
  fi

  local binds=()
  binds+=("/$(realpath "${paramInput}" | cut -f 2 -d "/")")

  local envBind="$(IFS=, ; echo "${binds[*]}")"
  local envCacheDir="${VIP_DIR_DATA}/images"
  local envHome
  if [[ -z "${NXF_HOME}" ]]; then
    envHome="${paramOutput}/.nxf.home"
  else
    envHome="${NXF_HOME}"
  fi
  local envTemp
  if [[ -z "${NXF_TEMP}" ]]; then
    envTemp="${paramOutput}/.nxf.tmp"
  else
    envTemp="${NXF_TEMP}"
  fi
  mkdir -p "${envTemp}"
  local envWork
  if [[ -z "${NXF_WORK}" ]]; then
    envWork="${paramOutput}/.nxf.work"
  else 
    envWork="${NXF_WORK}"
  fi
  if [[ -z "${NXF_JVM_ARGS}" ]]; then
    envJvm="-Xmx512m"
  else 
    envJvm="${NXF_JVM_ARGS}"
  fi
  local envStrict="true"

  local -r nextflow_version="24.10.3"

  local args=()
  args+=("-C" "${configs}")
  args+=("-log" "${paramOutput}/.nxf.log")
  args+=("run")
  args+=("${VIP_DIR}/vip_${paramWorkflow}.nf")
  args+=("-offline")
  args+=("-profile" "${paramProfile}")
  args+=("-with-report" "${paramOutput}/nxf_report.html")
  args+=("-with-timeline" "${paramOutput}/nxf_timeline.html")
  args+=("--input" "${paramInput}")
  args+=("--output" "${paramOutput}")
  if [[ "${paramResume}" == "true" ]]; then
    args+=("-resume")
  fi
  if [[ "${paramStub}" == "true" ]]; then
    args+=("-stub")
  fi
  (cd "${paramOutput}" && APPTAINER_BIND="${APPTAINER_BIND-${envBind}}" APPTAINER_CACHEDIR="${envCacheDir}" NXF_VER="${nextflow_version}" NXF_HOME="${envHome}" NXF_TEMP="${envTemp}" NXF_WORK="${envWork}" NXF_ENABLE_STRICT="${envStrict}" NXF_JVM_ARGS="${envJvm}" NXF_OFFLINE="true" NXF_DISABLE_CHECK_LATEST="true" VIP_DIR="${VIP_DIR}" VIP_DIR_DATA="${VIP_DIR_DATA}" VIP_VERSION="${VIP_VERSION}" bash "${VIP_DIR_DATA}/nextflow-${nextflow_version}-dist" "${args[@]}")
}

main() {
  local args=$(getopt -a -n pipeline -o w:i:o:c:p:rsvh --long workflow:,input:,output:,config:,profile:,resume,stub,version,help -- "$@")
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
  local stub="false"

  eval set -- "${args}"
  while :; do
    case "$1" in
    -v | --version)
          display_version
          exit 0
          shift
          ;;
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
    -s | --stub)
      stub="true"
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

  validate "${workflow}" "${input}" "${output}" "${config}" "${profile}" "${resume}" "${stub}"

  if [[ "${resume}" == "true" ]] && ! [[ -d "${output}" ]]; then
    resume="false"
  fi
  if ! [[ -d "${output}" ]]; then
    mkdir -p "${output}"
  fi
  
  execute_workflow "${workflow}" "${input}" "${output}" "${config}" "${profile}" "${resume}" "${stub}"
}

main "${@}"
