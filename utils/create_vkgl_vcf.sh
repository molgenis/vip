#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-i <input>] [-c <classification>] [-r <reference>] [-o <output>]
  -i, --input          <arg> VKGL consensus .tsv file (public or private) with columns 'chromosome', 'start', 'ref', 'alt' and 'classification'
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

  echo -e "##fileformat=VCFv4.2\n##INFO=<ID=END,Number=1,Type=Integer,Description=\"End position of the variant described in this record\">\n##ALT=<ID=DEL,Description=\"Deletion\">\n##ALT=<ID=DUP,Description=\"Duplication\">\n##ALT=<ID=INS,Description=\"Insertion\">\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSAMPLE0" > "${output}.tmp"
  awk -v classification="${classification}" '
    BEGIN {
      FS=OFS="\t"
    }
    NR==1 {
      for (i = 1; i <= NF; i++) {
        col[$i] = i
      }
      n = split("chromosome start ref alt classification", req, " ")
      for (k = 1; k <= n; k++) {
        if (!(req[k] in col)) {
          print "missing column \"" req[k] "\" in input header" > "/dev/stderr"
          exit 1
        }
      }
      next
    }
    $(col["classification"]) == classification {
      # symbolic alleles (e.g. <DEL>) need an END, taken from the optional 'stop' column
      info = "."
      if ($(col["alt"]) ~ /^</) {
        if (!("stop" in col) || $(col["stop"]) == "") {
          print "symbolic allele " $(col["alt"]) " at " $(col["chromosome"]) ":" $(col["start"]) " has no stop (END)" > "/dev/stderr"
          exit 1
        }
        info = "END=" $(col["stop"])
      }
      printf "%s\t%s\t.\t%s\t%s\t.\t.\t%s\tGT\t1/1\n",
        $(col["chromosome"]), $(col["start"]), $(col["ref"]), $(col["alt"]), info
    }
  ' "${input}" >> "${output}.tmp"
  regions=$(zcat "${reference}" | awk '/^>/{print substr($1,2)}' | paste -sd "," -)
  # Only keep variants on contigs that are part of the reference (bcftools sort cannot handle undefined contigs).
  # Chromosome names are matched to the reference naming (e.g. '8' -> 'chr8', 'chr8' -> '8', 'M' <-> 'MT' <-> 'chrM').
  awk '
    BEGIN {
      FS=OFS="\t"
    }
    function resolve(c,   s) {
      if (c in contigs) return c
      s = c
      sub(/^chr/, "", s)
      if (s in contigs) return s
      if (("chr" s) in contigs) return "chr" s
      if (s == "M" || s == "MT") {
        if ("MT" in contigs) return "MT"
        if ("M" in contigs) return "M"
        if ("chrM" in contigs) return "chrM"
      }
      return ""
    }
    NR==FNR {
      contigs[$1]
      next
    }
    /^#/ {
      print
      next
    }
    {
      r = resolve($1)
      if (r == "") {
        dropped++
        if (!($1 in unknown)) {
          unknown[$1]
          examples = examples " " $1
        }
      } else {
        $1 = r
        kept++
        print
      }
    }
    END {
      if (dropped > 0) {
        print "WARNING: " dropped " variants skipped, contig not in reference (input contigs:" examples ")" > "/dev/stderr"
      }
      if (kept == 0) {
        print "WARNING: no variants left for this classification" > "/dev/stderr"
      }
    }' "${reference}.fai" "${output}.tmp" > "${output}.filtered.tmp"
  bcftools reheader --fai "${reference}.fai" --output "${output}.unsorted.tmp" "${output}.filtered.tmp"
  # Sort variants by contig order of the reference and position, required for indexing
  bcftools sort --output "${output}_reheadered.vcf" "${output}.unsorted.tmp"
  bgzip "${output}_reheadered.vcf"
  tabix "${output}_reheadered.vcf.gz"
  bcftools view --regions "$regions" --output "${output}" "${output}_reheadered.vcf.gz"
  rm "${output}.tmp" "${output}.filtered.tmp" "${output}.unsorted.tmp" "${output}_reheadered.vcf.gz" "${output}_reheadered.vcf.gz.tbi"
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
