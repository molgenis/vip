#!/bin/bash
#SBATCH --job-name=vip_filter
#SBATCH --output=vip_filter.out
#SBATCH --error=vip_filter.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4gb
#SBATCH --nodes=1
#SBATCH --export=NONE
#SBATCH --get-user-env=L60

source utils/header.sh

INPUT=""
OUTPUT=""
CPU_CORES=""
FORCE=""

usage()
{
  echo "usage: pipeline_filter.sh -i <arg> -o <arg> [-f]

-i,  --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o,  --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-c,  --cpu_cores           optional: Number of CPU cores available for this process. Default: 4
-f,  --force               optional: Override the output file if it already exists.

examples:
  pipeline_filter.sh -i in.vcf -o out.vcf
  pipeline_filter.sh -i in.vcf.gz -o out.vcf.gz -c 2 -f"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:c:f --long input:,output:,cpu_cores:,force -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
	usage
	exit 2
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -i | --input)
        INPUT=$(realpath "$2")
        shift 2
        ;;
    -o | --output)
        OUTPUT_ARG="$2"
        OUTPUT_DIR_RELATIVE=$(dirname "$OUTPUT_ARG")
        OUTPUT_DIR_ABSOLUTE=$(realpath "$OUTPUT_DIR_RELATIVE")
        OUTPUT_FILE=$(basename "$OUTPUT_ARG")
        OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/"${OUTPUT_FILE}"
        shift 2
        ;;
    -c | --cpu_cores)
        CPU_CORES="$2"
        shift 2
        ;;		
    -f | --force)
        FORCE=1
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

if [ -z ${INPUT} ]
then
        echo "missing required option -i
	"
	usage
	exit 2
fi
if [ -z ${OUTPUT} ]
then
        echo "missing required option -o
	"
	usage
	exit 2
fi
if [ -z ${CPU_CORES} ]
then
	CPU_CORES=4
fi
if [ -z ${FORCE} ]
then
	FORCE=0
fi

if [ ! -f "${INPUT}" ]
then
	echo "$INPUT does not exist.
	"
	exit 2
fi
if [ -f "${OUTPUT}" ]
then
	if [ "${FORCE}" == "1" ]
	then
		rm "${OUTPUT}"
	else
		echo "${OUTPUT} already exists, use -f to overwrite.
        	"
	        exit 2
	fi
fi

FILTER_INPUT="${INPUT}"

module load BCFtools
module load HTSlib

BCFTOOLS_ARGS="\
--threads ${CPU_CORES} \
${INPUT}"
if [[ "${OUTPUT}" == *.vcf.gz ]]
then
	bcftools filter -e'CAP[*]<0.9' ${BCFTOOLS_ARGS} | bgzip -c > "${OUTPUT}"
else
	bcftools filter -e'CAP[*]<0.9' ${BCFTOOLS_ARGS} > "${OUTPUT}"
fi

module unload HTSlib
module unload BCFtools
