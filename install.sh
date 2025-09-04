#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "${0}")"

VIP_VER="${VIP_VER:-"v8.4.2"}"
VIP_DIR="${VIP_DIR:-"${PWD}/vip/${VIP_VER//\//_}"}" # replace every forward slash with underscore
VIP_DIR_DATA="${VIP_DIR_DATA:-"${PWD}/vip/data"}"

# based on https://github.com/har7an/bash-semver-regex?tab=readme-ov-file#the-regex but without start ^ end $
REGEX_SEM_VER="(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?"

usage() {
  echo -e "usage: bash ${SCRIPT_NAME} [-i <vip_install_dir>] [-d <data_dir>] [-u <url>] [-p]
  -p, --prune     remove resources from previous VIP installs that are not required for this version.
  -u, --url       base url to download VIP resources from
  -d, --data_dir  directory where VIP resources should be installed
  -i, --vip_dir   directory where the VIP software should be installed
  -h, --help

  requirements:
    apptainer    see https://apptainer.org/
    bash         >= 3.2
    java         >= 11
  environment variables with default values:
    VIP_VER      ${VIP_VER}
    VIP_DIR      ${VIP_DIR}
    VIP_DIR_DATA ${VIP_DIR_DATA}
    if --vip_dir and/or --data_dir are not provided."
  exit 0
}

handle_exit() {
  local -r exit_code=$?
  if [[ ${exit_code} -eq 0 ]]; then
    echo "VIP ${VIP_VER} installation completed, execute ${VIP_DIR#"${PWD}/"}/vip.sh to get started"
    detect_slurm
  else
    >&2 echo "error: VIP ${VIP_VER} installation failed"
  fi
}

check_requirements_bash() {
  # check bash exists
  if [[ -z ${BASH_VERSION+x} ]]; then
    >&2 echo -e "error: 'bash' is required but could not be found"
    exit 1
  fi

  # check bash version
  if [[ "${BASH_VERSINFO[0]}" -lt 3 ]]; then
    >&2 echo -e "error: bash ≥ 3.2 is required but version '${BASH_VERSION}' was detected"
    exit 1
  elif [[ "${BASH_VERSINFO[0]}" -eq 3 ]] && [[ "${BASH_VERSINFO[1]}" -lt 2 ]]; then
    >&2 echo -e "error: bash ≥ 3.2 is required but version '${BASH_VERSION}' was detected"
    exit 1
  fi
}

check_requirements_apptainer() {
  # check apptainer exists
  if ! command -v apptainer &> /dev/null; then
    >&2 echo -e "error: 'apptainer' is required but could not be found"
    exit 1
  fi
}

check_requirements_java() {
  # check java exists
  if ! command -v java &> /dev/null; then
    >&2 echo -e "error: 'java' is required but could not be found"
    exit 1
  fi

  # check java version
  local -r java_version="$(java -version 2>&1 | awk '/version/ {print $3}' | grep --extended-regexp --only-matching '[^\"]*')"
  local -r java_version_major="$(cut -d '.' -f 1 <<< "${java_version}")"

  if [[ ${java_version_major} -lt 11 ]]; then
    >&2 echo -e "error: java ≥ 11 is required but version '${java_version}' was detected"
    exit 1
  fi
}

detect_slurm() {
  # shellcheck disable=SC2317
  if command -v sbatch &> /dev/null; then
    echo -e "Slurm job scheduling system detected and will be used automatically"
  fi
}

check_requirements() {
  check_requirements_bash
  check_requirements_apptainer
  check_requirements_java
}

download_vip() {
  # download if directory does not exist or is empty
  if [[ ! -d "${VIP_DIR}" ]] || [[ -z "$( ls -A "${VIP_DIR}")" ]]; then
    local url="https://github.com/molgenis/vip/archive/refs"
    if [[ "${VIP_VER}" =~ ^v${REGEX_SEM_VER}$ ]];then
      url="${url}/tags/${VIP_VER}.tar.gz"
    else
      url="${url}/heads/${VIP_VER}.tar.gz"
    fi

    if ! curl --output /dev/null --fail --silent --head --location "${url}"; then
      >&2 echo -e "error: '${VIP_VER}' is not a valid tag or branch name in repository https://github.com/molgenis/vip"
      exit 1
    fi

    if ! mkdir --parents "${VIP_DIR}" &>/dev/null; then
      >&2 echo -e "error: cannot create directory '${VIP_DIR}'"
      exit 1
    fi

    if ! curl --fail --silent --location "${url}" | tar --extract --gunzip --directory "${VIP_DIR}" --strip-components 1 &>/dev/null; then
      >&2 echo -e "error: download '${url}' failed"
      rm -rf "${VIP_DIR}"
      exit 1
    fi

    if [[ ! -f "${VIP_DIR}/install_data.sh" ]]; then
      >&2 echo -e "error: VIP ${VIP_VER} cannot be installed using this installer, because 'install_data.sh' does not exist"
      rm -rf "${VIP_DIR}"
      exit 1
    fi
  fi
}

main() {
  local -r args=$(getopt -a -n install -o i:d:u:v:ph --long vip_dir:,data_dir:,url:,version:,prune,help -- "$@")

  local is_prune_enabled="false"
  local url=""

  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      ;;
    -p | --prune)
      is_prune_enabled="true"
      shift
      ;;
    -u | --url)
      url="$2"
      shift 2
      ;;
    -d | --data_dir)
      VIP_DIR_DATA="$2"
      shift 2
      ;;
    -i | --vip_dir)
      VIP_DIR="$2"
      shift 2
      ;;
    -v | --version)
      VIP_VER="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      ;;
    esac
  done

  if [[ -d "${VIP_DIR_DATA}" ]]; then
    echo -e "VIP ${VIP_VER} installation running..."
  else
    echo -e "VIP ${VIP_VER} installation running, this might take a long time depending on download speed..."
  fi
  check_requirements
  download_vip
  local data_args=()
  data_args+=("--version" "${VIP_VER}")
  if [ "${is_prune_enabled}" = true  ]; then
    data_args+=("--prune")
  fi
  data_args+=("--data_dir" "${VIP_DIR_DATA}")
  if [[ -n "${url}" ]]; then
    data_args+=("--url" "${url}")
  fi

  bash "${VIP_DIR}/install_data.sh" "${data_args[@]}"

  trap "handle_exit" EXIT
}

main "${@}"
