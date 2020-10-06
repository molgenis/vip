#!/bin/bash
#SBATCH --job-name=vip_report
#SBATCH --output=vip_report.out
#SBATCH --error=vip_report.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4gb
#SBATCH --nodes=1
#SBATCH --export=NONE
#SBATCH --get-user-env=L60

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [ -n "$SLURM_JOB_ID" ]; then SCRIPT_DIR=$(dirname $(scontrol show job "$SLURM_JOBID" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)); else SCRIPT_DIR=$(dirname $(realpath "$0")); fi

source "${SCRIPT_DIR}"/utils/header.sh

INPUT=""
INPUT_PED=""
INPUT_PHENO=""
OUTPUT=""
FORCE=0

usage()
{
  echo "usage: pipeline_report.sh -i <arg> -o <arg> [-p <arg>] [-f] [-k]

-i,  --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o,  --output <arg>        required: Output report file (.html).
-p,  --pedigree <arg>      optional: Pedigree file (.ped).
-t,  --phenotypes <arg>    optional: Phenotypes for input samples (see examples).
-f,  --force               optional: Override the output file if it already exists.

examples:
  pipeline_report.sh -i in.vcf -o out.html
  pipeline_report.sh -i in.vcf.gz -o out.html -p in.ped
  pipeline_report.sh -i in.vcf.gz -o out.html -t HP:0000123
  pipeline_report.sh -i in.vcf.gz -o out.html -t HP:0000123;HP:0000234
  pipeline_report.sh -i in.vcf.gz -o out.html -t sample0/HP:0000123
  pipeline_report.sh -i in.vcf.gz -o out.html -t sample0/HP:0000123,sample1/HP:0000234
  pipeline_report.sh -i in.vcf.gz -o out.html -p in.ped -t sample0/HP:0000123;HP:0000234,sample1/HP:0000345 -f"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:p:t:f --long input:,output:,pedigree:,phenotypes:,force -- "$@")
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
    -p | --pedigree)
      INPUT_PED=$(realpath "$2")
      shift 2
      ;;
    -t | --phenotypes)
      INPUT_PHENO="$2"
      echo "PHENO ${INPUT_PHENO}"
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

#FIXME map params

if [ -z "${INPUT}" ]
then
  echo -e "missing required option -i\n"
	usage
	exit 2
fi
if [ -z "${OUTPUT}" ]
then
  echo -e "missing required option -o\n"
	usage
	exit 2
fi

if [ ! -f "${INPUT}" ]
then
	echo -e "$INPUT does not exist.\n"
	exit 2
fi
if [ -f "${OUTPUT}" ]
then
  if [ "${FORCE}" == "1" ]
  then
    rm "${OUTPUT}"
  else
    echo -e "${OUTPUT} already exists, use -f to overwrite.\n"
    exit 2
  fi
fi
if [ ! -z "${INPUT_PED}" ]
then
  if [ ! -f "${INPUT_PED}" ]
  then
    echo -e "${INPUT_PED} does not exist.\n"
    exit 2
  fi
fi

if [ -z "${TMPDIR+x}" ]; then
	TMPDIR=/tmp
fi

module load "${MOD_VCF_REPORT}"

REPORT_ARGS="-i ${INPUT} -o ${OUTPUT}"
if [ ! -z "${INPUT_PED}" ]; then
	REPORT_ARGS+=" -pd ${INPUT_PED}"
fi
if [ ! -z "${INPUT_PHENO}" ]; then
	REPORT_ARGS+=" -ph ${INPUT_PHENO}"
fi

java -Djava.io.tmpdir="${TMPDIR}" -XX:ParallelGCThreads=2 -jar ${EBROOTVCFMINREPORT}/vcf-report.jar ${REPORT_ARGS}

module unload vcf-report
