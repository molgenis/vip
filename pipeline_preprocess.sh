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

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [ -n "$SLURM_JOB_ID" ]; then SCRIPT_DIR=$(dirname $(scontrol show job "$SLURM_JOBID" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)); else SCRIPT_DIR=$(dirname $(realpath "$0")); fi

# shellcheck source=utils/header.sh
source "${SCRIPT_DIR}"/utils/header.sh
# shellcheck source=utils/utils.sh
source "${SCRIPT_DIR}"/utils/utils.sh

INPUT=""
INPUT_REF=""
INPUT_PROBANDS=""
OUTPUT=""
FILTER_LOW_QUAL=0
FILTER_READ_DEPTH=20
CPU_CORES=4
FORCE=0
KEEP=0

usage()
{
  echo "usage: pipeline_preprocess.sh -i <arg> -o <arg> [-r <arg>] [-c <arg>] [--filter_low_qual] [--filter_read_depth] [-f] [-k]

-i, --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o, --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-r, --reference <arg>     optional: Reference sequence FASTA file (.fasta or .fasta.gz).
-b, --probands <arg>      optional: Subjects being reported on (comma-separated VCF sample names).
-c, --cpu_cores           optional: Number of CPU cores available for this process. Default: 4
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.

--filter_low_qual         optional: Filter low quality records using filter status and read depth.
--filter_read_depth       optional: Filter read depth threshold (default: 20)

examples:
  pipeline_preprocess.sh -i in.vcf -o out.vcf
  pipeline_preprocess.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz
  pipeline_preprocess.sh -i in.vcf.gz -o out.vcf.gz -b sample0
  pipeline_preprocess.sh -i in.vcf.gz -o out.vcf.gz --filter_low_qual --filter_read_depth 30
  pipeline_preprocess.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz -b sample0,sample1 --filter_low_qual --filter_read_depth 30 -c 2 -f -k"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:r:b:c:fk --long input:,output:,reference:,probands:,filter_low_qual,filter_read_depth:,cpu_cores:,force,keep -- "$@")
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
    -k | --keep)
      KEEP=1
      shift
      ;;
    -r | --reference)
      INPUT_REF=$(realpath "$2")
      shift 2
      ;;
    -b | --probands)
      INPUT_PROBANDS="$2"
      shift 2
      ;;
    --filter_low_qual)
      FILTER_LOW_QUAL=1
      shift
      ;;
    --filter_read_depth)
      FILTER_READ_DEPTH="$2"
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
if ! containsProbands "${INPUT_PROBANDS}" "${INPUT}"; then
  exit 2
fi

PREPROCESS_INPUT="${INPUT}"

module load "${MOD_BCF_TOOLS}"

REMOVE_ANN_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step1_remove_annotations
REMOVE_ANN_OUTPUT="${REMOVE_ANN_OUTPUT_DIR}"/"${OUTPUT_FILE}"

rm -rf "${REMOVE_ANN_OUTPUT_DIR}"
mkdir -p "${REMOVE_ANN_OUTPUT_DIR}"

BCFTOOLS_REMOVE_ARGS=("annotate" "-x" "INFO" "-o" "${REMOVE_ANN_OUTPUT}")
if [[ "${REMOVE_ANN_OUTPUT}" == *.vcf.gz ]]
then
	BCFTOOLS_REMOVE_ARGS+=("-O" "z")
fi
BCFTOOLS_REMOVE_ARGS+=("--threads" "${CPU_CORES}" "${PREPROCESS_INPUT}")

echo 'removing existing INFO annotations ...'
bcftools "${BCFTOOLS_REMOVE_ARGS[@]}"
echo 'removing existing INFO annotations done'

if [ "${FILTER_LOW_QUAL}" == "1" ];	then
  echo -e "filtering low-quality records ..."

  FILTER_LOW_QUAL_INPUT="${REMOVE_ANN_OUTPUT}"
  FILTER_LOW_QUAL_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step2_filter_low_qual
  FILTER_LOW_QUAL_OUTPUT="${FILTER_LOW_QUAL_OUTPUT_DIR}"/"${OUTPUT_FILE}"

  rm -rf "${FILTER_LOW_QUAL_OUTPUT_DIR}"
  mkdir -p "${FILTER_LOW_QUAL_OUTPUT_DIR}"

  # get sample names from vcf
  SAMPLE_NAMES=()
  mapfile -t SAMPLE_NAMES < <( bcftools query -l "${INPUT}" )

  if [ "${#SAMPLE_NAMES[*]}" == "0" ]; then
          bcftools filter -i '(FILTER=="PASS" || FILTER==".")' --threads "${CPU_CORES}" "${FILTER_LOW_QUAL_INPUT}" > "${FILTER_LOW_QUAL_OUTPUT}"
  else
          if [ -n "$INPUT_PROBANDS" ]; then
            # create sample name to sample index map
            declare -A SAMPLE_NAMES_MAP
            for i in "${!SAMPLE_NAMES[@]}"; do
                  SAMPLE_NAMES_MAP["${SAMPLE_NAMES[$i]}"]=$i
            done

            # create proband ids
            PROBAND_IDS=()
            # shellcheck disable=SC2206
            PROBAND_NAMES=(${INPUT_PROBANDS//,/ })
            for i in "${PROBAND_NAMES[@]}"; do
                    PROBAND_IDS+=("${SAMPLE_NAMES_MAP[$i]}")
            done
            PROBAND_IDS_STR=$(IFS=","; echo "${PROBAND_IDS[*]}")
          else
            PROBAND_IDS_STR="*"
          fi


          # run include filter and exclude filter
          if [ "${FILTER_READ_DEPTH}" != -1 ]; then
            FILTER_INCLUDE="(FILTER==\"PASS\" || FILTER==\".\") && FORMAT/DP[${PROBAND_IDS_STR}] >= ${FILTER_READ_DEPTH}"
            FILTER_EXCLUDE="FORMAT/DP < ${FILTER_READ_DEPTH}"
            bcftools filter -i "${FILTER_INCLUDE}" "${FILTER_LOW_QUAL_INPUT}" --threads "${CPU_CORES}" | bcftools filter -e "${FILTER_EXCLUDE}" -S . --threads "${CPU_CORES}" > "${FILTER_LOW_QUAL_OUTPUT}"
          else
            FILTER_INCLUDE="(FILTER==\"PASS\" || FILTER==\".\")"
            bcftools filter -i "${FILTER_INCLUDE}" "${FILTER_LOW_QUAL_INPUT}" --threads "${CPU_CORES}" > "${FILTER_LOW_QUAL_OUTPUT}"
          fi
  fi

  echo -e "filtering low-quality records done"
else
  FILTER_LOW_QUAL_OUTPUT="${REMOVE_ANN_OUTPUT}"
fi

NORMALIZE_INPUT="${FILTER_LOW_QUAL_OUTPUT}"
NORMALIZE_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step0_normalize
NORMALIZE_OUTPUT="${NORMALIZE_OUTPUT_DIR}"/"${OUTPUT_FILE}"

rm -rf "${NORMALIZE_OUTPUT_DIR}"
mkdir -p "${NORMALIZE_OUTPUT_DIR}"

BCFTOOLS_ARGS=("norm" "-m" "-both" "-s" "-o" "${NORMALIZE_OUTPUT}")
if [[ "${NORMALIZE_OUTPUT}" == *.vcf.gz ]]
then
	BCFTOOLS_ARGS+=("-O" "z")
fi
if [ -n "${INPUT_REF}" ]; then
	BCFTOOLS_ARGS+=("-f" "${INPUT_REF}" "-c" "e")
fi
BCFTOOLS_ARGS+=("--threads" "${CPU_CORES}" "${NORMALIZE_INPUT}")

echo 'normalizing ...'
bcftools "${BCFTOOLS_ARGS[@]}"
echo 'normalizing done'

module purge

mv "${NORMALIZE_OUTPUT}" "${OUTPUT}"
ln -s "${OUTPUT}" "${NORMALIZE_OUTPUT}"

if [ "${KEEP}" == "0" ]; then
  rm -rf "${NORMALIZE_OUTPUT_DIR}"
  rm -rf "${REMOVE_ANN_OUTPUT_DIR}"
  if [ "${FILTER_LOW_QUAL}" == "1" ];	then
    rm -rf "${FILTER_LOW_QUAL_OUTPUT_DIR}"
  fi
fi
