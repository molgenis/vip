#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} -v <arg>
create annotation resource for Hpo.pm VEP plugin
  -v, --version    <arg>    HPO release tag name, e.g. v2024-03-06 (see https://github.com/obophenotype/human-phenotype-ontology/releases)
  -h, --help                Print this message and exit"
}

validate() {
  local -r version="${1}"
  local -r output="${2}"

  # version
  if [[ -z "${version}" ]]; then
    echo -e "error: missing required -v, --version"
    exit 1
  fi

  # output
  if [[ -f "${output}" ]]; then
    echo -e "error: output '${output}' already exists"
    exit 1
  fi

  # downloaded temporary resource
  if [[ -f "phenotype_to_genes.txt" ]]; then
    echo -e "error: phenotype_to_genes.txt already exists"
    exit 1
  fi
}

create() {
  local -r version="${1}"
  local -r output="${2}"

  local -r url="https://github.com/obophenotype/human-phenotype-ontology/releases/download/${version}/phenotype_to_genes.txt"
  echo -e "downloading '${url}'..."
  if ! curl --fail --silent --location --request GET "${url}" --remote-name; then
    echo -e "error downloading '${url}': invalid version?"
    exit 1
  fi

  echo -e "creating '${output}'..."
  echo -e "#Format: entrez-gene-id<tab>HPO-Term-ID" > "${output}"
  sed -e 1d phenotype_to_genes.txt | awk -v FS='\t' -v OFS='\t' '{print $3 "\t" $1}' | sort | uniq >> "${output}"

  # remove temporary file
  rm "phenotype_to_genes.txt"
}

main() {
  local -r args=$(getopt -a -n pipeline -o v:h --long version:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local version=""

  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -v | --version)
      version="$2"
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

  local -r output="hpo_${version}.tsv"

  validate "${version}" "${output}"
  create "${version}" "${output}"
}

main "${@}"
