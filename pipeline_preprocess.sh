#!/bin/bash
#SBATCH --job-name=vip_preprocess
#SBATCH --output=vip_preprocess.out
#SBATCH --error=vip_preprocess.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=2gb
#SBATCH --nodes=1
#SBATCH --export=NONE
#SBATCH --get-user-env=L60

# Retrieve original directory of submitted script.
if [ -n "$SLURM_JOB_ID" ] ; then # If Slurm job.
  SCRIPT_DIR=$(scontrol show job "$SLURM_JOBID" | awk -F= '/Command=/{print $2}')
  SCRIPT_DIR="${SCRIPT_DIR%% *}" # Removes anything starting at first space (so keep script path).
else
  SCRIPT_DIR=$(realpath "$0")
fi
readonly SCRIPT_DIR="${SCRIPT_DIR%/*}" # Removes "/<scriptname>".

source "${SCRIPT_DIR}"/utils/header.sh

INPUT=""
INPUT_REF=""
OUTPUT=""
CPU_CORES=4
FORCE=0

usage()
{
  echo "usage: pipeline_preprocess.sh -i <arg> -o <arg> [-r <arg>] [-c <arg>] [-f]

-i, --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o, --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-r, --reference <arg>     optional: Reference sequence FASTA file (.fasta or .fasta.gz).
-c, --cpu_cores           optional: Number of CPU cores available for this process. Default: 4
-f, --force               optional: Override the output file if it already exists.

examples:
  pipeline_preprocess.sh -i in.vcf -o out.vcf
  pipeline_preprocess.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz
  pipeline_preprocess.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz -c 2 -f"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:r:c:f --long input:,output:,reference:,cpu_cores:,force -- "$@")
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
    -r | --reference)
      INPUT_REF=$(realpath "$2")
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
if [ ! -z "${INPUT_REF}" ]
then
  if [ ! -f "${INPUT_REF}" ]
  then
    echo -e "${INPUT_REF} does not exist.\n"
    exit 2
  fi
fi

PREPROCESS_INPUT="${INPUT}"

module load "${MOD_BCF_TOOLS}"

BCFTOOLS_ARGS="\
norm \
-m -both \
-s \
-o ${OUTPUT}"
if [[ "${OUTPUT}" == *.vcf.gz ]]
then
	BCFTOOLS_ARGS+=" -O z"
fi
if [ ! -z "${INPUT_REF}" ]; then
	BCFTOOLS_ARGS+=" -f ${INPUT_REF} -c e"
fi
BCFTOOLS_ARGS+=" --threads ${CPU_CORES} ${PREPROCESS_INPUT}"

echo 'normalizing ...'
bcftools ${BCFTOOLS_ARGS}
echo 'normalizing done'

module purge
