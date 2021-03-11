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
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

# shellcheck source=utils/header.sh
source "${SCRIPT_DIR}"/utils/header.sh
# shellcheck source=utils/utils.sh
source "${SCRIPT_DIR}"/utils/utils.sh

#######################################
# Print usage
#######################################
usage() {
  echo -e "usage: ${SCRIPT_NAME} -i <arg>

-i, --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o, --output <arg>        optional: Output VCF file (.vcf.gz).
-b, --probands <arg>      optional: Subjects being reported on (comma-separated VCF sample names).

-c, --config     <arg>    optional: Configuration file (.cfg)
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.
-h, --help                optional: Print this message and exit.

config:
  preprocess_filter_low_qual    filter low quality records using filter status and read depth.
  preprocess_filter_read_depth  filter read depth threshold (default: 20)
  reference                     see pipeline.sh
  cpu_cores                     see pipeline.sh"
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

  local inputVcf="$1"
  local outputVcf="$2"
  local threads="$3"

  module load "${MOD_BCF_TOOLS}"

  # INFO keys to keep
  local infoKeys=()
  # from: https://github.com/Illumina/manta/blob/v1.6.0/docs/userGuide/README.md#vcf-info-fields
  infoKeys+=("INFO/IMPRECISE")
  infoKeys+=("INFO/SVTYPE")
  infoKeys+=("INFO/SVLEN")
  infoKeys+=("INFO/END")
  infoKeys+=("INFO/CIPOS")
  infoKeys+=("INFO/CIEND")
  infoKeys+=("INFO/CIPOS")
  infoKeys+=("INFO/MATEID")
  infoKeys+=("INFO/EVENT")
  infoKeys+=("INFO/HOMLEN")
  infoKeys+=("INFO/HOMSEQ")
  infoKeys+=("INFO/SVINSLEN")
  infoKeys+=("INFO/SVINSSEQ")
  infoKeys+=("INFO/LEFT_SVINSSEQ")
  infoKeys+=("INFO/RIGHT_SVINSSEQ")
  infoKeys+=("INFO/BND_DEPTH")
  infoKeys+=("INFO/MATE_BND_DEPTH")
  infoKeys+=("INFO/JUNCTION_QUAL")
  infoKeys+=("INFO/SOMATIC")
  infoKeys+=("INFO/SOMATICSCORE")
  infoKeys+=("INFO/JUNCTION_SOMATICSCORE")
  infoKeys+=("INFO/CONTIG")

  local -r infoKeysStr=$(joinArr "," "${infoKeys[@]}")

  local args=()
  args+=("annotate")
  args+=("-x" "^${infoKeysStr}")
  args+=("-o" "${outputVcf}")
  args+=("-O" "z")
  args+=("--no-version")
  args+=("--threads" "${threads}")
  args+=("${inputVcf}")

  bcftools "${args[@]}"
  echo -e "removing existing INFO annotations done"

  module purge
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

  local inputVcf="$1"
  local probands="$2"
  local readDepthThreshold=$3
  local outputVcf="$4"
  local threads="$5"

  module load "${MOD_BCF_TOOLS}"

  # get sample names from vcf
  local sampleNames=()
  mapfile -t sampleNames < <(bcftools query -l "${inputVcf}")

  local filter="(filter==\"PASS\" || filter==\".\")"
  if [ "${#sampleNames[*]}" == "0" ]; then
    local args=()
    args+=("filter")
    args+=("-i" "${filter}")
    args+=("-o" "${outputVcf}")
    args+=("-O" "z")
    args+=("--no-version")
    args+=("--threads" "${threads}")
    args+=("${inputVcf}")

    bcftools "${args[@]}"
  else
    local probandIdsStr
    if [ -n "$probands" ]; then
      # create sample name to sample index map
      declare -A SAMPLE_NAMES_MAP
      for i in "${!sampleNames[@]}"; do
        SAMPLE_NAMES_MAP["${sampleNames[$i]}"]=$i
      done

      # create proband ids
      local PROBAND_IDS=()
      # shellcheck disable=SC2206
      local PROBAND_NAMES=(${probands//,/ })
      for i in "${PROBAND_NAMES[@]}"; do
        PROBAND_IDS+=("${SAMPLE_NAMES_MAP[$i]}")
      done
      probandIdsStr=$(joinArr "," "${PROBAND_IDS[@]}")
    else
      probandIdsStr="*"
    fi

    # run include filter and exclude filter
    if [ "${readDepthThreshold}" != -1 ] && containsFormatDpHeader "${inputVcf}"; then
      filter+=" && ("
      filter+="GT[${probandIdsStr}]!=\"ref\" & GT[${probandIdsStr}]!=\"mis\""
      filter+=" & ("
      filter+="DP[${probandIdsStr}]=\".\" | DP[${probandIdsStr}]>=${readDepthThreshold}"
      filter+=")"
      filter+=")"

      local args=()
      args+=("filter")
      args+=("-i" "${filter}")
      args+=("--no-version")
      args+=("--threads" "${threads}")
      args+=("${inputVcf}")

      filterExclude="FORMAT/DP < ${readDepthThreshold}"

      local argsExclude=()
      argsExclude+=("filter")
      argsExclude+=("-e" "${filterExclude}")
      # set genotypes of failed samples to missing value '.'
      argsExclude+=("-S" ".")
      argsExclude+=("-o" "${outputVcf}")
      argsExclude+=("-O" "z")
      argsExclude+=("--no-version")
      argsExclude+=("--threads" "${threads}")

      bcftools "${args[@]}" | bcftools "${argsExclude[@]}"
    else
      filter+=" && ("
      filter+="GT[${probandIdsStr}]!=\"ref\" & GT[${probandIdsStr}]!=\"mis\""
      filter+=")"

      local args=()
      args+=("filter")
      args+=("-i" "${filter}")
      args+=("-o" "${outputVcf}")
      args+=("-O" "z")
      args+=("--no-version")
      args+=("--threads" "${threads}")
      args+=("${inputVcf}")

      bcftools "${args[@]}"
    fi
  fi

  echo -e "filtering low-quality records done"
  module purge
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

  local inputVcf="$1"
  local refFasta="$2"
  local outputVcf="$3"
  local threads="$4"

  module load "${MOD_BCF_TOOLS}"

  local args=()
  args+=("norm")
  # split multi-allelic sites into bi-allelic records (both SNPs and indels are merged separately into two records)
  args+=("-m" "-both")
  # strict
  args+=("-s")
  args+=("-o" "${outputVcf}")
  args+=("-O" "z")
  if [ -n "${refFasta}" ]; then
    args+=("-f" "${refFasta}")
    # warn when incorrect or missing REF allele is encountered or when alternate allele is non-ACGTN (e.g. structural variant)
    args+=("-c" "w")
  fi
  args+=("--no-version")
  args+=("--threads" "${threads}")
  args+=("${inputVcf}")

  bcftools "${args[@]}"
  echo -e "normalizing done"
  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 comma-separated proband identifiers (optional)
#   $4 force
#   $5 path to reference sequence (optional)
#   $6 cpu cores
#   $7 filter low quality flag
#   $8 filter read depth threshold
validate() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r probands="${3}"
  local -r force="${4}"
  local -r referencePath="${5}"
  local -r cpuCores="${6}"
  local -r filterLowQual="${7}"
  local -r filterReadDepth="${8}"

  if ! validateInputPath "${inputFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if ! validateOutputPath "${outputFilePath}" "${force}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if [[ -n "${probands}" ]] && ! containsProbands "${probands}" "${inputFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if [[ -n "${referencePath}" ]] && [[ ! -f "${referencePath}" ]]; then
    echo -e "reference ${referencePath} does not exist."
    exit 1
  fi
}

main() {
  local -r parsedArguments=$(getopt -a -n pipeline -o i:o:b:c:fkh --long input:,output:,probands:,config:,force,keep,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local inputFilePath=""
  local outputFilePath=""
  local probands=""
  local cfgFilePath=""
  local force=0
  local keep=0

  eval set -- "${parsedArguments}"
  while :; do
    case "$1" in
   -h | --help)
      usage
      exit 0
      shift
      ;;
    -i | --input)
      inputFilePath=$(realpath "$2")
      shift 2
      ;;
    -o | --output)
      outputFilePath="$2"
      shift 2
      ;;
    -b | --probands)
      probands="$2"
      shift 2
      ;;
    -c | --config)
      cfgFilePath=$(realpath "$2")
      shift 2
      ;;
    -f | --force)
      force=1
      shift
      ;;
    -k | --keep)
      keep=1
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

  if [[ -z "${inputFilePath}" ]]; then
    echo -e "missing required option -i or --input."
    echo -e "try '${SCRIPT_NAME} -h or --help' for more information."
    exit 1
  fi

  local inputRefPath=""
  local cpuCores=""
  local filterLowQual=""
  local filterReadDepth=""

  parseCfg "${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePath}" ]]; then
    parseCfg "${cfgFilePath}"
  fi
  if [[ -n "${VIP_CFG_MAP["reference"]+unset}" ]]; then
    inputRefPath="${VIP_CFG_MAP["reference"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["cpu_cores"]+unset}" ]]; then
    cpuCores="${VIP_CFG_MAP["cpu_cores"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["preprocess_filter_low_qual"]+unset}" ]]; then
    filterLowQual="${VIP_CFG_MAP["preprocess_filter_low_qual"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["preprocess_filter_read_depth"]+unset}" ]]; then
    filterReadDepth="${VIP_CFG_MAP["preprocess_filter_read_depth"]}"
  fi

  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="$(createOutputPathFromPostfix "${inputFilePath}" "vip_preprocess")"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${probands}" "${force}" "${inputRefPath}" "${cpuCores}" "${filterLowQual}" "${filterReadDepth}"

  mkdir -p "$(dirname "${outputFilePath}")"
  local -r outputDir="$(realpath "$(dirname "${outputFilePath}")")"
  local -r outputFilename="$(basename "${outputFilePath}")"
  outputFilePath="${outputDir}/${outputFilename}"

  if [[ -f "${outputFilePath}" ]] && [[ "${force}" == "1" ]]; then
    rm "${outputFilePath}"
  fi

  initWorkDir "${outputFilePath}" "${force}" "${keep}"
  local -r workDir="${VIP_WORK_DIR}"

  local currentInputFilePath="${inputFilePath}" currentOutputDir currentOutputFilePath

  # step 1: remove info annotations
  currentOutputDir="${workDir}/1_remove_annotations"
  currentOutputFilePath="${currentOutputDir}/${outputFilename}"
  mkdir -p "${currentOutputDir}"
  removeInfoAnnotations "${currentInputFilePath}" "${currentOutputFilePath}" "${cpuCores}"
  currentInputFilePath="${currentOutputFilePath}"

  # step 2: filter low quality records
  if [ "${filterLowQual}" == "1" ]; then
    currentOutputDir="${workDir}/2_filter_low_qual"
    currentOutputFilePath="${currentOutputDir}/${outputFilename}"
    mkdir -p "${currentOutputDir}"
    filterLowQualityRecords "${currentInputFilePath}" "${probands}" "${filterReadDepth}" "${currentOutputFilePath}" "${cpuCores}"
    currentInputFilePath="${currentOutputFilePath}"
  fi

  # step 3: normalize variants
  normalizeIndels "${currentInputFilePath}" "${inputRefPath}" "${outputFilePath}" "${cpuCores}"
}

main "${@}"
