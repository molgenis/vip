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
#SBATCH --tmp=4gb

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

#######################################
# Print usage
#######################################
usage() {
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

#######################################
# Remove all INFO fields from a VCF file.
#
# Arguments:
#   path to input VCF file
#   path to output VCF file
#   number of worker threads
#######################################
removeInfoAnnotations() {
  echo -e "removing existing INFO annotations ..."

  local INPUT_VCF="$1"
  local OUTPUT_VCF="$2"
  local THREADS="$3"

  # INFO keys to keep
  local INFO_KEYS=()
  # from: https://github.com/Illumina/manta/blob/v1.6.0/docs/userGuide/README.md#vcf-info-fields
  INFO_KEYS+=("INFO/IMPRECISE")
  INFO_KEYS+=("INFO/SVTYPE")
  INFO_KEYS+=("INFO/SVLEN")
  INFO_KEYS+=("INFO/END")
  INFO_KEYS+=("INFO/CIPOS")
  INFO_KEYS+=("INFO/CIEND")
  INFO_KEYS+=("INFO/CIPOS")
  INFO_KEYS+=("INFO/MATEID")
  INFO_KEYS+=("INFO/EVENT")
  INFO_KEYS+=("INFO/HOMLEN")
  INFO_KEYS+=("INFO/HOMSEQ")
  INFO_KEYS+=("INFO/SVINSLEN")
  INFO_KEYS+=("INFO/SVINSSEQ")
  INFO_KEYS+=("INFO/LEFT_SVINSSEQ")
  INFO_KEYS+=("INFO/RIGHT_SVINSSEQ")
  INFO_KEYS+=("INFO/BND_DEPTH")
  INFO_KEYS+=("INFO/MATE_BND_DEPTH")
  INFO_KEYS+=("INFO/JUNCTION_QUAL")
  INFO_KEYS+=("INFO/SOMATIC")
  INFO_KEYS+=("INFO/SOMATICSCORE")
  INFO_KEYS+=("INFO/JUNCTION_SOMATICSCORE")
  INFO_KEYS+=("INFO/CONTIG")

  local INFO_KEYS_STR
  INFO_KEYS_STR=$(
    IFS=","
    echo "${INFO_KEYS[*]}"
  )

  local ARGS=()
  ARGS+=("annotate")
  ARGS+=("-x" "^${INFO_KEYS_STR}")
  ARGS+=("-o" "${OUTPUT_VCF}")
  if [[ "${OUTPUT_VCF}" == *.vcf.gz ]]; then
    ARGS+=("-O" "z")
  fi
  ARGS+=("--threads" "${THREADS}")
  ARGS+=("${INPUT_VCF}")

  bcftools "${ARGS[@]}"
  echo -e "removing existing INFO annotations done"
}

#######################################
# Remove low-quality records from a VCF file.
#
# Arguments:
#   path to input VCF file
#   comma-separated proband ids
#   read-depth threshold (-1 to disable read-depth filtering)
#   path to output VCF file
#   number of worker threads
#######################################
filterLowQualityRecords() {
  echo -e "filtering low-quality records ..."

  local INPUT_VCF="$1"
  local PROBANDS="$2"
  local READ_DEPTH_THRESHOLD=$3
  local OUTPUT_VCF="$4"
  local THREADS="$5"

  # get sample names from vcf
  local SAMPLE_NAMES=()
  mapfile -t SAMPLE_NAMES < <(bcftools query -l "${INPUT_VCF}")

  local FILTER="(FILTER==\"PASS\" || FILTER==\".\")"
  if [ "${#SAMPLE_NAMES[*]}" == "0" ]; then
    local ARGS=()
    ARGS+=("filter")
    ARGS+=("-i" "${FILTER}")
    ARGS+=("-o" "${OUTPUT_VCF}")
    if [[ "${OUTPUT_VCF}" == *.vcf.gz ]]; then
      ARGS+=("-O" "z")
    fi
    ARGS+=("--threads" "${THREADS}")
    ARGS+=("${INPUT_VCF}")

    bcftools "${ARGS[@]}"
  else
    local PROBAND_IDS_STR
    if [ -n "$PROBANDS" ]; then
      # create sample name to sample index map
      declare -A SAMPLE_NAMES_MAP
      for i in "${!SAMPLE_NAMES[@]}"; do
        SAMPLE_NAMES_MAP["${SAMPLE_NAMES[$i]}"]=$i
      done

      # create proband ids
      local PROBAND_IDS=()
      # shellcheck disable=SC2206
      local PROBAND_NAMES=(${PROBANDS//,/ })
      for i in "${PROBAND_NAMES[@]}"; do
        PROBAND_IDS+=("${SAMPLE_NAMES_MAP[$i]}")
      done
      PROBAND_IDS_STR=$(
        IFS=","
        echo "${PROBAND_IDS[*]}"
      )
    else
      PROBAND_IDS_STR="*"
    fi

    # run include filter and exclude filter
    if [ "${READ_DEPTH_THRESHOLD}" != -1 ] && containsFormatDpHeader "${INPUT_VCF}"; then
      FILTER+=" && ("
      FILTER+="GT[${PROBAND_IDS_STR}]!=\"ref\" & GT[${PROBAND_IDS_STR}]!=\"mis\""
      FILTER+=" & ("
      FILTER+="DP[${PROBAND_IDS_STR}]=\".\" | DP[${PROBAND_IDS_STR}]>=${READ_DEPTH_THRESHOLD}"
      FILTER+=")"
      FILTER+=")"

      local ARGS=()
      ARGS+=("filter")
      ARGS+=("-i" "${FILTER}")
      ARGS+=("--threads" "${THREADS}")
      ARGS+=("${INPUT_VCF}")

      FILTER_EXCLUDE="FORMAT/DP < ${READ_DEPTH_THRESHOLD}"

      local ARGS_EXCLUDE=()
      ARGS_EXCLUDE+=("filter")
      ARGS_EXCLUDE+=("-e" "${FILTER_EXCLUDE}")
      # set genotypes of failed samples to missing value '.'
      ARGS_EXCLUDE+=("-S" ".")
      ARGS_EXCLUDE+=("-o" "${OUTPUT_VCF}")
      if [[ "${OUTPUT_VCF}" == *.vcf.gz ]]; then
        ARGS_EXCLUDE+=("-O" "z")
      fi
      ARGS_EXCLUDE+=("--threads" "${THREADS}")

      bcftools "${ARGS[@]}" | bcftools "${ARGS_EXCLUDE[@]}"
    else
      FILTER+=" && ("
      FILTER+="GT[${PROBAND_IDS_STR}]!=\"ref\" & GT[${PROBAND_IDS_STR}]!=\"mis\""
      FILTER+=")"

      local ARGS=()
      ARGS+=("filter")
      ARGS+=("-i" "${FILTER}")
      ARGS+=("-o" "${OUTPUT_VCF}")
      if [[ "${OUTPUT_VCF}" == *.vcf.gz ]]; then
        ARGS+=("-O" "z")
      fi
      ARGS+=("--threads" "${THREADS}")
      ARGS+=("${INPUT_VCF}")

      bcftools "${ARGS[@]}"
    fi
  fi

  echo -e "filtering low-quality records done"
}

#######################################
# Left-align and normalize indels, check if REF alleles match the reference, split multi-allelic sites into multiple rows from a VCF file.
#
# Arguments:
#   path to input VCF file
#   path to reference sequence FASTA file
#   path to output VCF file
#   number of worker threads
#######################################
normalizeIndels() {
  echo -e "normalizing ..."

  local INPUT_VCF="$1"
  local REF_FASTA="$2"
  local OUTPUT_VCF="$3"
  local THREADS="$4"

  local ARGS=()
  ARGS+=("norm")
  # split multi-allelic sites into bi-allelic records (both SNPs and indels are merged separately into two records)
  ARGS+=("-m" "-both")
  # strict
  ARGS+=("-s")
  ARGS+=("-o" "${OUTPUT_VCF}")
  if [[ "${OUTPUT_VCF}" == *.vcf.gz ]]; then
    ARGS+=("-O" "z")
  fi
  if [ -n "${REF_FASTA}" ]; then
    ARGS+=("-f" "${REF_FASTA}")
    # warn when incorrect or missing REF allele is encountered or when alternate allele is non-ACGTN (e.g. structural variant)
    ARGS+=("-c" "w")
  fi
  ARGS+=("--threads" "${THREADS}")
  ARGS+=("${INPUT_VCF}")

  bcftools "${ARGS[@]}"
  echo -e "normalizing done"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:r:b:c:fk --long input:,output:,reference:,probands:,filter_low_qual,filter_read_depth:,cpu_cores:,force,keep -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
  usage
  exit 2
fi

eval set -- "$PARSED_ARGUMENTS"
while :; do
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

if [ -z "${INPUT}" ]; then
  echo -e "missing required option -i"
  usage
  exit 2
fi
if [ -z "${OUTPUT}" ]; then
  echo -e "missing required option -o"
  usage
  exit 2
fi

if [ ! -f "${INPUT}" ]; then
  echo -e "$INPUT does not exist."
  exit 2
fi
if [ -f "${OUTPUT}" ]; then
  if [ "${FORCE}" == "1" ]; then
    rm "${OUTPUT}"
  else
    echo -e "${OUTPUT} already exists, use -f to overwrite."
    exit 2
  fi
fi
if [ ! -z "${INPUT_REF}" ]; then
  if [ ! -f "${INPUT_REF}" ]; then
    echo -e "${INPUT_REF} does not exist."
    exit 2
  fi
fi
if ! containsProbands "${INPUT_PROBANDS}" "${INPUT}"; then
  exit 2
fi

module load "${MOD_BCF_TOOLS}"

# Step: remove info fields from records
REMOVE_ANN_INPUT="${INPUT}"
REMOVE_ANN_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step1_remove_annotations
REMOVE_ANN_OUTPUT="${REMOVE_ANN_OUTPUT_DIR}"/"${OUTPUT_FILE}"
rm -rf "${REMOVE_ANN_OUTPUT_DIR}"
mkdir -p "${REMOVE_ANN_OUTPUT_DIR}"

removeInfoAnnotations "${REMOVE_ANN_INPUT}" "${REMOVE_ANN_OUTPUT}" "${CPU_CORES}"

# Step: remove low-quality records
if [ "${FILTER_LOW_QUAL}" == "1" ]; then
  FILTER_LOW_QUAL_INPUT="${REMOVE_ANN_OUTPUT}"
  FILTER_LOW_QUAL_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step2_filter_low_qual
  FILTER_LOW_QUAL_OUTPUT="${FILTER_LOW_QUAL_OUTPUT_DIR}"/"${OUTPUT_FILE}"
  rm -rf "${FILTER_LOW_QUAL_OUTPUT_DIR}"
  mkdir -p "${FILTER_LOW_QUAL_OUTPUT_DIR}"

  filterLowQualityRecords "${FILTER_LOW_QUAL_INPUT}" "${INPUT_PROBANDS}" "${FILTER_READ_DEPTH}" "${FILTER_LOW_QUAL_OUTPUT}" "${CPU_CORES}"
else
  FILTER_LOW_QUAL_OUTPUT="${REMOVE_ANN_OUTPUT}"
fi

# Step: normalize variants
NORMALIZE_INPUT="${FILTER_LOW_QUAL_OUTPUT}"
NORMALIZE_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step0_normalize
NORMALIZE_OUTPUT="${NORMALIZE_OUTPUT_DIR}"/"${OUTPUT_FILE}"
rm -rf "${NORMALIZE_OUTPUT_DIR}"
mkdir -p "${NORMALIZE_OUTPUT_DIR}"

normalizeIndels "${NORMALIZE_INPUT}" "${INPUT_REF}" "${NORMALIZE_OUTPUT}" "${CPU_CORES}"

module purge

mv "${NORMALIZE_OUTPUT}" "${OUTPUT}"
ln -s "${OUTPUT}" "${NORMALIZE_OUTPUT}"

if [ "${KEEP}" == "0" ]; then
  rm -rf "${REMOVE_ANN_OUTPUT_DIR}"
  rm -rf "${FILTER_LOW_QUAL_OUTPUT_DIR}"
  rm -rf "${NORMALIZE_OUTPUT_DIR}"
fi
