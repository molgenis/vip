#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} -i <arg> -o <arg> -a <arg> [-t <arg>]
  -i, --input      <arg>    ClinVar .vcf.gz file from https://www.ncbi.nlm.nih.gov/clinvar/
  -o, --output     <arg>    ClinVar .tsv.gz file with '#[1]CHROM', '[2]POS', '[3]ID', '[4]REF', '[5]ALT', '[6]CLNSIG', '[7]CLNSIGINCL', '[8]CLNREVSTAT' columns
  -a, --assembly   <arg>    Desired assembly of the output file [GRCh38]
  -h, --help                Print this message and exit"
}

strip() {
  local -r input="${1}"
  local -r output="${2}"
  local -r assembly="${3}"

  echo -e "1 chr1\n2 chr2\n3 chr3\n4 chr4\n5 chr5\n6 chr6\n7 chr7\n8 chr8\n9 chr9\n10 chr10\n11 chr11\n12 chr12\n13 chr13\n14 chr14\n15 chr15\n16 chr16\n17 chr17\n18 chr18\n19 chr19\n20 chr20\n21 chr21\n22 chr22\nX chrX\nY chrY\nMT chrM\n" > "chr_mapping.tmp"
  bcftools annotate --rename-chrs chr_mapping.tmp --no-version --threads 8 "${input}" |\
  bcftools query --print-header --format '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%INFO/CLNSIG\t%INFO/CLNSIGINCL\t%INFO/CLNREVSTAT\n' |\
  bgzip --stdout --compress-level 9 --threads 8 > "${output}"
  
  rm "chr_mapping.tmp"
}

map(){
  local -r input="${1}"
  local -r output="${2}"

  zcat "${input}" | awk 'BEGIN {
      FS=OFS="\t";
      mapping["Benign"]="Benign";
      mapping["Likely_benign"]="Likely_benign";
      mapping["Uncertain_significance"]="Uncertain_significance";
      mapping["Likely_pathogenic"]="Likely_pathogenic";
      mapping["Pathogenic"]="Pathogenic";
      mapping["Conflicting_classifications_of_pathogenicity"]="Conflicting_classifications_of_pathogenicity";
      mapping["Benign/Likely_benign"]="Likely_benign";
      mapping["Pathogenic/Likely_pathogenic"]="Likely_pathogenic";
      }
      {
          split($6, values, "|");
          new_values = "";
          delete seen;

          for (i in values) {
              val = values[i];
              if (val in mapping) {
                  val = mapping[val];
              }
              else{
                  val = "Other";
              }
              if (!seen[val]++) {
                  new_values = (new_values == "" ? val : new_values "|" val);
              }
          }
          $6 = new_values;
          print
      }' | 
      bgzip --stdout --compress-level 9 --threads 8 > "${output}"

  rm "${input}"
}

index(){
  local -r output="${1}"
  tabix	"${output}" --begin 2 --end 2 --sequence 1 --skip-lines 1
}

validate() {
  local -r input="${1}"
  local -r output="${2}"
  local -r assembly="${3}"

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

  if [[ -z "${assembly}" ]]; then
    echo -e "missing required -a, --assembly"
    usage
    exit 1
  fi
  if [[ "${assembly}" != "GRCh38" ]]; then
    echo -e "invalid assembly value '${assembly}'. valid values are GRCh38."
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
  local -r args=$(getopt -a -n pipeline -o i:o:a:h --long input:,output:,assembly:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local input=""
  local output=""
  local assembly=""

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
    -a | --assembly)
      assembly="$2"
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

  validate "${input}" "${output}" "${assembly}"
  strip "${input}" "${input}_stripped.tsv" "${assembly}"
  map "${input}_stripped.tsv" "${output}"
  index "${output}"
}

main "${@}"
