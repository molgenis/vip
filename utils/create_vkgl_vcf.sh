#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-i <input>] [-c <classification>] [-r <reference>] [-o <output>]
  -i, --input          <arg> VKGL consensus .tsv file
  -c, --classification <arg> VKGL variant classification (LB, VUS or LP)
  -r, --reference      <arg> reference genome
  -o, --output         <arg> VKGL consensus .vcf file with variants of given classification
  -h, --help"
}

create_output() {
  local -r input="${1}"
  local -r classification="${2}"
  local -r reference="${3}"
  local -r output="${4}"

  echo -e "##fileformat=VCFv4.2\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSAMPLE0" > "${output}.tmp"
  awk -v classification="${classification}" '
    BEGIN {
      FS=OFS="\t"
    }
    NR>1 {
      if ($13 == classification) {
        printf "%s\t%s\t.\t%s\t%s\t.\t.\t.\tGT\t1/1\n",
        $3,$4,$6,$7,$13
      }
    }
  ' "${input}" >> "${output}.tmp"
  regions=$(zcat ${reference} | awk '/^>/{print substr($1,2)}' | paste -sd "," -)
  bcftools reheader --fai "${reference}.fai" --output "${output}_reheadered.vcf" "${output}.tmp"
  # Remove contigs that are not part of the specified in the reference
  bgzip "${output}_reheadered.vcf"
  tabix "${output}_reheadered.vcf.gz"
  bcftools view --regions "$regions" --output "${output}" "${output}_reheadered.vcf.gz"
  rm "${output}.tmp" "${output}_reheadered.vcf.gz" "${output}_reheadered.vcf.gz.tbi"
}

validate() {
  local -r input="${1}"
  local -r classification="${2}"
  local -r reference="${3}"
  local -r output="${4}"

  # input
  if [[ -z "${input}" ]]; then
    echo -e "missing required -i, --input"
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

  #classification
  if [[ -z "${classification}" ]]; then
    echo -e "missing required -c, --classification"
    exit 1
  fi
  if [[ "${classification}" != "LB" && "${classification}" != "VUS" && "${classification}" != "LP" ]]; then
    echo -e "invalid classification value '${classification}'. valid values are [LB, VUS, LP]"
    exit 1
  fi

  #output
  if [[ "${output}" != *.vcf ]]; then
    echo -e "-o, --output '${output}' is not a '.vcf' file"
    exit 1
  fi
  if [[ -f "${output}" ]]; then
    echo -e "-o, --output '${output}' already exists"
    exit 1
  fi

  # reference
  if [[ -z "${reference}" ]]; then
    echo -e "missing required -r, --reference"
    usage
    exit 1
  fi

  # bcftools
  if ! command -v bcftools &> /dev/null; then
    echo "command 'bcftools' could not be found (possible solution: run 'ml BCFtools' before executing this script)"
    exit 1
  fi
}

main() {
  local -r args=$(getopt -a -n pipeline -o i:c:r:o:h --long input:,classification:,reference:,output:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local input=""
  local classification=""
  local reference=""
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
    -c | --classification)
      classification="$2"
      shift 2
      ;;
    -r | --reference)
      reference="$2"
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

  validate "${input}" "${classification}" "${reference}" "${output}"
  create_output "${input}" "${classification}" "${reference}" "${output}"
}

main "${@}"
