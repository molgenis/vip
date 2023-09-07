#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} -i <arg> -o <arg>
  -i, --input      <arg>    AlphScore .tsv.gz file from https://doi.org/10.5281/zenodo.8283349
  -o, --output     <arg>    AlphScore .tsv.gz file with '#chr', 'pos(1-based)', 'ref', 'alt' and 'AlphScore' columns
  -h, --help                Print this message and exit"
}

strip() {
  local -r input="${1}"
  local -r output="${2}"

  zcat "${input}" | \
    awk 'BEGIN { FS="\t"; OFS="\t" } NR==1 { printf "%s\t%s\t%s\t%s\t%s\n", $1, $2, $3, $4, $23 } NR>1 { printf "%s\t%s\t%s\t%s\t%0.3f\n", $1, $2, $3, $4, $23 }' | \
    bgzip --compress-level 9 --stdout --threads 8 > "${output}"
  tabix "${output}" -b 2 -e 2 -s 1 -S 1
}

validate() {
  local -r input="${1}"
  local -r output="${2}"

  if [ -z "${input}" ]; then
    echo -e "missing required -i, --input"
    usage
    exit 1
  fi
  if [ ! -f "${input}" ]; then
    echo -e "-i, --input '${input}' does not exist"
    exit 1
  fi

  local -r header_line="$(zcat "${input}" | head -n 1)"
  
  local header="$(echo "${header_line}" | cut -f 1)"
  if [[ "${header}" != "#chr" ]]; then
    echo "input '${input}' header invalid: expected column 1 to be '#chr' instead of '${header}'"
    exit -1
  fi
  header="$(echo "${header_line}" | cut -f 2)"
  if [[ "${header}" != "pos(1-based)" ]]; then
    echo "input '${input}' header invalid: expected column 2 to be 'pos(1-based)' instead of '${header}'"
    exit -1
  fi
  header="$(echo "${header_line}" | cut -f 3)"
  if [[ "${header}" != "ref" ]]; then
    echo "input '${input}' header invalid: expected column 3 to be 'ref' instead of '${header}'"
    exit -1
  fi
  header="$(echo "${header_line}" | cut -f 4)"
  if [[ "${header}" != "alt" ]]; then
    echo "input '${input}' header invalid: expected column 4 to be 'alt' instead of '${header}'"
    exit -1
  fi
  header="$(echo "${header_line}" | cut -f 23)"
  if [[ "${header}" != "AlphScore" ]]; then
    echo "input '${input}' header invalid: expected column 23 to be 'AlphScore' instead of '${header}'"
    exit -1
  fi

  if [[ -f "${output}" ]]; then
    echo -e "-o, --output '${output}' already exists"
    exit 1
  fi

  if ! command -v bgzip &> /dev/null
  then
    echo "command 'bgzip' could not be found"
    exit 1
  fi
  if ! command -v tabix &> /dev/null
  then
    echo "command 'tabix' could not be found"
    exit 1
  fi
}

main() {
  local args=$(getopt -a -n pipeline -o i:o:h --long input:,output:,help -- "$@")
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

  if [[ -z "${output}" ]]; then
    output="stripped_${input}"
  fi
  
  validate "${input}" "${output}"
  strip "${input}" "${output}"
}

main "${@}"
