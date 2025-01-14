#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} -v <arg>
create default bed file
  -i, --input    <arg>    input gff file (e.g. https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_genomic.gff.gz)
  -m, --mapping    <arg>    assembly report to map GFF contig identifiers to VCF contig identifiers(e.g https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.40_GRCh38.p14/GCF_000001405.40_GRCh38.p14_assembly_report.txt)
  -t, --types    <arg>    comma separated list of types from the gff that should be included
  -s, --sources    <arg>    which sources to include, possible values: BestRefSeq,RefSeq,RefSeqFE,Gnomon,cmsearch,Curated Genomic,tRNAscan-SE
  -o, --output    <arg>    output bed file file/location
  -h, --help                Print this message and exit"
}

create() {
	local -r input="${1}"
	local -r mapping="${2}"
	local -r types="${3}"
	local -r sources="${4}"
	local -r output="${5}"

	zcat "${input}" | awk -v mapfile="${mapping}" -v types_input="${types}" -v sources_input="${sources}" '
	BEGIN {
		FS = OFS = "\t";
		# Load mapping file
		while ((getline line < mapfile) > 0) {
			if (line ~ /^#/) continue;
			split(line, fields, "\t");
      contig = fields[10]
      gsub(/[\r\n]+/, "", contig)
			contig_map[fields[7]] = contig;
		}
		close(mapfile);
	
    #input types and sources to map for easier use
		n = split(types_input, included_types, ",");
		for (i = 1; i <= n; i++) {
			types[included_types[i]] = 1;
		}
    n = split(sources_input, included_sources, ",");
		for (i = 1; i <= n; i++) {
			sources[included_sources[i]] = 1;
		}
	}
	{
    #check if any of the sources match any of the input sources
    n = split($2, sources_split, "%2C");
    include = 0;
    for (i = 1; i <= n; i++) {
      source = sources_split[i]
      if(sources[source]){
        include = 1;
        break;
      }
    }
    #check if the line has a type that should be included
		if ($3 in types && include == 1) {
			split($9, fields, ";");
			id = "";
			for (i in fields) {
				split(fields[i], annotation_map, "=");
				if (annotation_map[1] == "ID") {
					id = annotation_map[2];
					break;
				}
			}
			if ($1 in contig_map) {
				new_contig = contig_map[$1];
				print new_contig, $4, $5, id;
			} else {
				print "Error: Unknown Contig " $1 " encountered." > "/dev/stderr";
				exit 1;
			}
		}
	}' > "${output}"
}

validate() {
  local -r input="${1}"
  local -r classification="${2}"
	local -r types="${3}"
	local -r sources="${4}"
	local -r output="${5}"

  # input
  if [[ -z "${input}" ]]; then
    echo -e "missing required -i, --input"
    exit 1
  fi
  if [[ ! -f "${input}" ]]; then
    echo -e "-i, --input '${input}' does not exist"
    exit 1
  fi
  if [[ "${input}" != *.gff.gz ]]; then
    echo -e "-i, --input '${input}' is not a '.gff.gz' file"
    exit 1
  fi

  #output
  if [[ "${output}" != *.bed ]]; then
    echo -e "-o, --output '${output}' is not a '.bed' file"
    exit 1
  fi
  if [[ -f "${output}" ]]; then
    echo -e "-o, --output '${output}' already exists"
    exit 1
  fi
  
  #mapping
   if [[ -z "${mapping}" ]]; then
    echo -e "missing required -m, --mapping"
    exit 1
  fi
  if [[ "${mapping}" != *.txt ]]; then
    echo -e "-m, --mapping '${mapping}' is not a '.txt' file"
    exit 1
  fi

  #sources
  if [[ -z "${sources}" ]]; then
    echo -e "missing required -s, --sources"
    exit 1
  fi
  #types
  if [[ -z "${types}" ]]; then
    echo -e "missing required -t, --types"
    exit 1
  fi
}

main() {
  local -r args=$(getopt -a -n pipeline -o i:o:m:t:s:h --long input:,mapping:,types:,sources:,output:,help -- "$@")
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
    -i | --input)
      input="$2"
      shift 2
      ;;
	-m | --mapping)
      mapping="$2"
      shift 2
      ;;
	-t | --types)
      types="$2"
      shift 2
      ;;
  -s | --sources)
      sources="$2"
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

  validate "${input}" "${mapping}" "${types}" "${sources}" "${output}"
  create "${input}" "${mapping}" "${types}" "${sources}" "${output}"
}

main "${@}"
