#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

readonly CREATE_VCF="${SCRIPT_DIR}/create_vkgl_vcf.sh"

usage() {
  echo -e "usage: ${SCRIPT_NAME} -i <arg> -r <arg> [-o <arg>] [-d <arg>]

  -i, --input     <arg> VKGL consensus .tsv file
  -r, --reference <arg> reference genome (.fasta.gz with .fai index)
  -o, --output    <arg> output directory [.]
  -d, --date      <arg> year and month used in the file names (YYYYMM) [current year and month]
  -h, --help            Print this message and exit

creates in the output directory:
  vkgl_lb_<date>.bcf.gz
  vkgl_lp_<date>.bcf
  vkgl_vus_<date>.vcf.gz"
}

create_output() {
  local -r input="${1}"
  local -r reference="${2}"
  local -r output_dir="${3}"
  local -r date="${4}"

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap "rm -rf '${tmp_dir}'" EXIT

  for classification in LB LP VUS; do
    local lower="${classification,,}"
    local vcf="${tmp_dir}/vkgl_${lower}_${date}.vcf"

    echo "creating ${classification} variants"
    "${CREATE_VCF}" --input "${input}" --classification "${classification}" --reference "${reference}" --output "${vcf}"

    case "${classification}" in
    LB)
      local out="${output_dir}/vkgl_${lower}_${date}.bcf.gz"
      bcftools view --output-type b --output "${out}" "${vcf}"
      ;;
    LP)
      local out="${output_dir}/vkgl_${lower}_${date}.bcf"
      bcftools view --output-type b --output "${out}" "${vcf}"
      ;;
    VUS)
      local out="${output_dir}/vkgl_${lower}_${date}.vcf.gz"
      bgzip --stdout "${vcf}" > "${out}"
      ;;
    esac
    echo "written: ${out}"
  done
}

validate() {
  local -r input="${1}"
  local -r reference="${2}"
  local -r output_dir="${3}"
  local -r date="${4}"

  # input
  if [[ -z "${input}" ]]; then
    echo -e "missing required -i, --input"
    usage
    exit 1
  fi
  if [[ ! -f "${input}" ]]; then
    echo -e "-i, --input '${input}' does not exist"
    exit 1
  fi
  if [[ "${input}" != *.tsv ]]; then
    echo -e "-i, --input '${input}' is not a '.tsv' file"
    exit 1
  fi

  # reference
  if [[ -z "${reference}" ]]; then
    echo -e "missing required -r, --reference"
    usage
    exit 1
  fi
  if [[ ! -f "${reference}" ]]; then
    echo -e "-r, --reference '${reference}' does not exist"
    exit 1
  fi
  if [[ ! -f "${reference}.fai" ]]; then
    echo -e "-r, --reference index '${reference}.fai' does not exist"
    exit 1
  fi

  # output
  if [[ ! -d "${output_dir}" ]]; then
    echo -e "-o, --output '${output_dir}' is not an existing directory"
    exit 1
  fi

  # date
  if [[ ! "${date}" =~ ^[0-9]{4}(0[1-9]|1[0-2])$ ]]; then
    echo -e "-d, --date '${date}' is not in the format YYYYMM"
    exit 1
  fi

  # existing output files
  local existing
  for existing in "vkgl_lb_${date}.bcf.gz" "vkgl_lb_${date}.bcf.gz.csi" \
    "vkgl_lp_${date}.bcf" "vkgl_lp_${date}.bcf.csi" \
    "vkgl_vus_${date}.vcf.gz" "vkgl_vus_${date}.vcf.gz.tbi"; do
    if [[ -f "${output_dir}/${existing}" ]]; then
      echo -e "output file '${output_dir}/${existing}' already exists"
      exit 1
    fi
  done

  # create vcf script
  if [[ ! -x "${CREATE_VCF}" ]]; then
    echo -e "script '${CREATE_VCF}' does not exist or is not executable"
    exit 1
  fi

  # bcftools, bgzip, tabix
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
  local -r args=$(getopt -a -n pipeline -o i:r:o:d:h --long input:,reference:,output:,date:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local input=""
  local reference=""
  local output_dir="."
  local date
  date="$(date +%Y%m)"

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
    -r | --reference)
      reference="$2"
      shift 2
      ;;
    -o | --output)
      output_dir="$2"
      shift 2
      ;;
    -d | --date)
      date="$2"
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

  validate "${input}" "${reference}" "${output_dir}" "${date}"
  create_output "${input}" "${reference}" "${output_dir}" "${date}"
}

main "${@}"
