#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} -i <arg> -o <arg> -a <arg> [-t <arg>]
  -i, --input      <arg>    ClinVar .vcf.gz file from https://www.ncbi.nlm.nih.gov/clinvar/
  -o, --output     <arg>    ClinVar .tsv.gz file with '#[1]CHROM', '[2]POS', '[3]REF', '[4]ALT', '[5]CLNSIG', '[6]CLNSIGINCL', '[7]CLNREVSTAT' columns
  -h, --help                Print this message and exit"
}

strip() {
  local -r input="${1}"
  local -r output="${2}"

  bcftools query --print-header --format '%CHROM\t%POS\t%REF\t%ALT\t%INFO/CLNSIG\t%INFO/CLNSIGINCL\t%INFO/CLNREVSTAT\n' "${input}" |\
    bgzip --stdout --compress-level 9 --threads 8 > "${output}"
  tabix	"${output}" --begin 2 --end 2 --sequence 1 --skip-lines 1
}

validate() {
  local -r input="${1}"
  local -r output="${2}"

  if [[ -z "${input}" ]]; then
    echo -e "missing required -i, --input"
    exit 1
  fi
  if [[ ! -f "${input}" ]]; then
    echo -e "-i, --input '${input}' does not exist"
    exit 1
  fi
  if [[ "${input}" != *.vcf.gz ]]; then
    echo -e "-i, --input '${input}' is not a '.vcf.gz' file"
    exit 1
  fi

  if [[ "${output}" != *.tsv.gz ]]; then
    echo -e "-o, --output '${output}' is not a '.tsv.gz' file"
    exit 1
  fi
  if [[ -f "${output}" ]]; then
    echo -e "-o, --output '${output}' already exists"
    exit 1
  fi
  if [[ -f "${output}.tbi" ]]; then
    echo -e "-o, --output index '${output}.tbi' already exists"
    exit 1
  fi

  if ! command -v bcftools &> /dev/null; then
    echo "command 'bcftools' could not be found (possible solution: run 'ml BCFtools' before executing this script)"
    exit 1
  fi
  if ! command -v bgzip &> /dev/null; then
    echo "command 'bgzip' could not be found (possible solution: run 'ml BCFtools' before executing this script)"
    exit 1
  fi
  if ! command -v tabix &> /dev/null; then
    echo "command 'tabix' could not be found (possible solution: run 'ml BCFtools' before executing this script)"
    exit 1
  fi
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
    output="${input%%.*}_stripped.tsv.gz"
  fi

  validate "${input}" "${output}"
  strip "${input}" "${output}"
}

main "${@}"
