#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# utility script to install multiple VIP versions using shared resources

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-v <version>] -c
  -v, --version   <arg>
  -n, --no-validate      disable file checksum checking
  -c, --continue         continue aborted install
  -h, --help"
}

validate() {
  local -r version="${1}"
  local -r continue="${2}"

  if [ -z "${version}" ]; then
    echo -e "error:missing required option -v or --version"
    return 1
  fi

  if [ "${continue}" == "0" ] && [ -d "${SCRIPT_DIR}/${version}" ]; then
    echo -e "version ${version} already installed"
    return 1
  fi
}


install() {
  local -r version="${1}"
  local -r continue="${2}"
  local -r validate="${3}"
  
  local -r versionDir="${SCRIPT_DIR}/${version}"
  if [ "${continue}" == "1" ] || [ ! -d "${SCRIPT_DIR}/${version}" ]; then
    mkdir -p "${versionDir}"
    if ! git clone --quiet --depth 1 --branch "${version}" https://github.com/molgenis/vip "${versionDir}"; then
      echo -e "error retrieving version ${version}. version does not exist?"
      rm "${versionDir}"
      return 1
    fi
  fi

  mkdir -p "${SCRIPT_DIR}/images"
  ln -s "${SCRIPT_DIR}/images" "${versionDir}/images"
  mkdir -p "${SCRIPT_DIR}/resources/GRCh37"
  ln -s "${SCRIPT_DIR}/resources/GRCh37" "${versionDir}/resources/GRCh37"
  mkdir -p "${SCRIPT_DIR}/resources/GRCh38"
  ln -s "${SCRIPT_DIR}/resources/GRCh38" "${versionDir}/resources/GRCh38"
  mkdir -p "${SCRIPT_DIR}/resources/vep/cache"
  ln -s "${SCRIPT_DIR}/resources/vep/cache" "${versionDir}/resources/vep/cache"
  mkdir -p "${SCRIPT_DIR}/resources/annotsv"
  ln -s "${SCRIPT_DIR}/resources/annotsv" "${versionDir}/resources/annotsv"
  mkdir -p "${SCRIPT_DIR}/resources/gado"
  ln -s "${SCRIPT_DIR}/resources/gado" "${versionDir}/resources/gado"

  # prevent downloading shared resource
  if [ -f "${SCRIPT_DIR}/resources/nextflow-23.10.0-all" ]; then
    cp --link "${SCRIPT_DIR}/resources/nextflow-23.10.0-all" "${versionDir}"
  fi
  if [ -f "${SCRIPT_DIR}/resources/hpo_20240208.tsv" ]; then
    cp --link "${SCRIPT_DIR}/resources/hpo_20240208.tsv" "${versionDir}/resources"
  fi
  if [ -f "${SCRIPT_DIR}/resources/inheritance_20240115.tsv" ]; then
    cp --link "${SCRIPT_DIR}/resources/inheritance_20240115.tsv" "${versionDir}/resources"
  fi

  if [ "${validate}" == "false" ]; then
    bash "${versionDir}/install.sh" "--no-validate"
  else
    bash "${versionDir}/install.sh"
  fi

  # make resource shared
  if [ -f "${versionDir}/nextflow-23.10.0-all" ] && [ ! -f "${SCRIPT_DIR}/resources/nextflow-23.10.0-all" ]; then
    cp --link "${versionDir}/nextflow-23.10.0-all" "${SCRIPT_DIR}/resources"
  fi
  if [ -f "${versionDir}/resources/hpo_20240208.tsv" ] && [ ! -f "${SCRIPT_DIR}/resources/hpo_20240208.tsv" ]; then
    cp --link "${versionDir}/resources/hpo_20240208.tsv" "${SCRIPT_DIR}/resources"
  fi
  if [ -f "${versionDir}/resources/inheritance_20240115.tsv" ] && [ ! -f "${SCRIPT_DIR}/resources/inheritance_20240115.tsv" ]; then
    cp --link "${versionDir}/resources/inheritance_20240115.tsv" "${SCRIPT_DIR}/resources"
  fi
}

main() {
  local -r args=$(getopt -a -n pipeline -o v:nch --long version:,no-validate,continue,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local version=""
  local validate="true"
  local continue="0"

  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      shift
      ;;
    -v | --version)
      version="$2"
      shift 2
      ;;
    -n | --no-validate)
      validate="false"
      shift
      ;;
    -c | --continue)
      continue=1
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

  if ! validate "${version}" "${continue}"; then
    usage
    exit 2;
  fi

  if ! install "${version}" "${continue}" "${validate}"; then
    echo -e "installation failed"
    exit 1;
  fi
}

main "${@}"

