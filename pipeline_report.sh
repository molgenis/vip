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
#SBATCH --tmp=4gb

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

# shellcheck source=utils/header.sh
source "${SCRIPT_DIR}"/utils/header.sh
# shellcheck source=utils/utils.sh
source "${SCRIPT_DIR}"/utils/utils.sh

usage() {
  echo -e "usage: ${SCRIPT_NAME} -i <arg>

-i, --input      <arg>    required: Input VCF file (.vcf or .vcf.gz).
-o, --output     <arg>    optional: Output VCF file (.vcf.gz).
-b, --probands   <arg>    optional: Subjects being reported on (comma-separated VCF sample names).
-p, --pedigree   <arg>    optional: Pedigree file (.ped).
-t, --phenotypes <arg>    optional: Phenotypes for input samples.
-s, --start      <arg>    optional: Different starting point for the pipeline (annotate, filter, inheritance or report).

-c, --config     <arg>    optional: Configuration file (.cfg)
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.

config:
  report_max_records      maximum number of records in the report. Default: 100
  report_max_samples      maximum number of samples in the report. Default: 100
  report_template         HTML template to be used in the report."
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 probands (optional)
#   $4 path to pedigree file (optional)
#   $5 phenotypes (optional)
#   $6 maxRecords (optional)
#   $7 maxSamples (optional)
#   $8 path to template file (optional)
report() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r probands="${3}"
  local -r pedFilePath="${4}"
  local -r phenotypes="${5}"
  local -r maxRecords="${6}"
  local -r maxSamples="${7}"
  local -r templateFilePath="${8}"

  module load "${MOD_VCF_REPORT}"

  args=()
  args+=("-Djava.io.tmpdir=${TMPDIR}")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "${EBROOTVCFMINREPORT}/vcf-report.jar")
  args+=("-i" "${inputFilePath}")
  args+=("-o" "${outputFilePath}")
  if [ -n "${probands}" ]; then
    args+=("-pb" "${probands}")
  fi
  if [ -n "${pedFilePath}" ]; then
    args+=("-pd" "${pedFilePath}")
  fi
  if [ -n "${phenotypes}" ]; then
    args+=("-ph" "${phenotypes}")
  fi
  if [ -n "${maxRecords}" ]; then
    args+=("-mr" "${maxRecords}")
  fi
  if [ -n "${maxSamples}" ]; then
    args+=("-ms" "${maxSamples}")
  fi
  if [ -n "${templateFilePath}" ]; then
    args+=("-t" "${templateFilePath}")
  fi

  java "${args[@]}"

  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 probands (optional)
#   $4 path to pedigree file (optional)
#   $5 phenotypes (optional)
#   $6 force
#   $7 maxRecords (optional)
#   $8 maxSamples (optional)
#   $9 path to template file (optional)
validate() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r probands="${3}"
  local -r pedFilePath="${4}"
  local -r phenotypes="${5}"
  local -r force="${6}"
  local -r maxRecords="${7}"
  local -r maxSamples="${8}"
  local -r templateFilePath="${9}"

  if ! validateInputPath "${inputFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if ! validateOutputPath "${outputFilePath}" "${force}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if [[ -n "${pedFilePath}" ]] && [[ ! -f "${pedFilePath}" ]]; then
    echo -e "pedigree ${pedFilePath} does not exist."
    exit 1
  fi

  if [[ -n "${probands}" ]] && ! containsProbands "${probands}" "${inputFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  #TODO validate phenotypes
  #TODO max records
  #TODO max samples

  if [[ -n "${templateFilePath}" ]] && [[ ! -f "${templateFilePath}" ]]; then
    echo -e "template ${templateFilePath} does not exist."
    exit 1
  fi
}

main() {
  local inputFilePath=""
  local outputFilePath=""
  local probands=""
  local pedFilePath=""
  local phenotypes=""
  local cfgFilePath=""
  local force=0
  local keep=0

  local -r parsedArguments=$(getopt -a -n pipeline -o i:o:b:p:t:c:fk --long input:,output:,probands:,pedigree:,phenotypes:,config:,force,keep -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  eval set -- "$parsedArguments"
  while :; do
    case "$1" in
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
    -p | --pedigree)
      pedFilePath=$(realpath "$2")
      shift 2
      ;;
    -t | --phenotypes)
      phenotypes="$2"
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
      # reserved for future usage
      # shellcheck disable=SC2034
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

  local maxRecords=""
  local maxSamples=""
  local templateFilePath=""

  parseCfg "${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePath}" ]]; then
    parseCfg "${cfgFilePath}"
  fi
  if [[ -n "${VIP_CFG_MAP["report_max_records"]+unset}" ]]; then
    maxRecords="${VIP_CFG_MAP["report_max_records"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["report_max_samples"]+unset}" ]]; then
    maxSamples="${VIP_CFG_MAP["report_max_samples"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["report_template"]+unset}" ]]; then
    templateFilePath="${VIP_CFG_MAP["report_template"]}"
  fi

  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="${inputFilePath}.html"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${probands}" "${pedFilePath}" "${phenotypes}" "${force}" "${maxRecords}" "${maxSamples}" "${templateFilePath}"

  if [[ -f "${outputFilePath}" ]]; then
    if [[ "${force}" == "1" ]]; then
      rm "${outputFilePath}"
    fi
  fi

  report "${inputFilePath}" "${outputFilePath}" "${probands}" "${pedFilePath}" "${phenotypes}" "${maxRecords}" "${maxSamples}" "${templateFilePath}"
}

main "${@}"
