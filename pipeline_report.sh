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

-i, --input      <arg>       required: Input VCF file (.vcf or .vcf.gz).
-o, --output     <arg>       optional: Output VCF file (.vcf.gz).
-b, --probands   <arg>       optional: Subjects being reported on (comma-separated VCF sample names).
-p, --pedigree   <arg>       optional: Pedigree file (.ped).
-t, --phenotypes <arg>       optional: Phenotypes for input samples.
-s, --start      <arg>       optional: Different starting point for the pipeline (annotate, filter, inheritance or report).

-c, --config     <arg>       optional: Comma separated list of configuration files (.cfg)
-f, --force                  optional: Override the output file if it already exists.
-k, --keep                   optional: Keep intermediate files.

config:
  report_max_records         maximum number of records in the report. Default: 100
  report_max_samples         maximum number of samples in the report. Default: 100
  report_template            HTML template to be used in the report.
  url_reference              URL to reference sequence.
  url_reference_access_token URL to reference sequence access token.
  url_alignment              Format URL to alignment data with 'accession' placeholder (e.g. http://my.org/pre_{accession}_post.cram)
  url_alignment_access_token URL to alignment data access token.
  url_variant                Format URL to variant data with 'accession' placeholder (e.g. http://my.org/pre_{accession}_post.vcf.gz)
  url_variant_access_token   URL to variant data access token."
}

# arguments:
#   $1  path to input file
#   $2  path to output file
#   $3  probands (optional)
#   $4  path to pedigree file (optional)
#   $5  phenotypes (optional)
#   $6  maxRecords (optional)
#   $7  maxSamples (optional)
#   $8  path to template file (optional)
#   $9  url to reference sequence (optional)
#   $10 url to reference sequence access token (optional)
#   $11 url to alignment (optional)
#   $12 url to alignment access token (optional)
#   $13 url to variant (optional)
#   $14 url to variant access token (optional)
report() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r probands="${3}"
  local -r pedFilePath="${4}"
  local -r phenotypes="${5}"
  local -r maxRecords="${6}"
  local -r maxSamples="${7}"
  local -r templateFilePath="${8}"
  local -r urlReference="${9}"
  local -r urlReferenceAccessToken="${10}"
  local -r urlAlignment="${11}"
  local -r urlAlignmentAccessToken="${12}"
  local -r urlVariant="${13}"
  local -r urlVariantAccessToken="${14}"

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
  if [ -n "${urlReference}" ]; then
    args+=("--url_reference" "${urlReference}")
  fi
  if [ -n "${urlReferenceAccessToken}" ]; then
    args+=("--url_reference_token" "${urlReferenceAccessToken}")
  fi
  if [ -n "${urlAlignment}" ]; then
    args+=("--url_alignment" "${urlAlignment}")
  fi
  if [ -n "${urlAlignmentAccessToken}" ]; then
    args+=("--url_alignment_token" "${urlAlignmentAccessToken}")
  fi
  if [ -n "${urlVariant}" ]; then
    args+=("--url_variant" "${urlVariant}")
  fi
  if [ -n "${urlVariantAccessToken}" ]; then
    args+=("--url_variant_token" "${urlVariantAccessToken}")
  fi
  java "${args[@]}"

  module purge
}

# arguments:
#   $1  path to input file
#   $2  path to output file
#   $3  probands (optional)
#   $4  path to pedigree file (optional)
#   $5  phenotypes (optional)
#   $6  force
#   $7  maxRecords (optional)
#   $8  maxSamples (optional)
#   $9  path to template file (optional)
#   $10 url to reference sequence (optional)
#   $11 url to reference sequence access token (optional)
#   $12 url to alignment (optional)
#   $13 url to alignment access token (optional)
#   $14 url to variant (optional)
#   $15 url to variant access token (optional)
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
  local -r urlReference="${10}"
  local -r urlReferenceAccessToken="${11}"
  local -r urlAlignment="${12}"
  local -r urlAlignmentAccessToken="${13}"
  local -r urlVariant="${14}"
  local -r urlVariantAccessToken="${15}"

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
  if [[ -n "${urlReferenceAccessToken}" ]] && [[ -z "${urlReference}" ]]; then
    echo -e "url_reference_access_token specified without url_reference."
    exit 1
  fi
  if [[ -n "${urlAlignment}" ]] && [[ "${urlAlignment}" =~ \{accession\} ]];then
    echo -e "url_alignment ${urlAlignment} is missing {accession} placeholder."
    exit 1
  fi
  if [[ -n "${urlAlignmentAccessToken}" ]] && [[ -z "${urlAlignment}" ]]; then
    echo -e "url_alignment_access_token specified without url_alignment."
    exit 1
  fi
  if [[ -n "${urlVariant}" ]] && [[ "${urlVariant}" =~ \{accession\} ]];then
    echo -e "url_variant ${urlVariant} is missing {accession} placeholder."
    exit 1
  fi
  if [[ -n "${urlVariantAccessToken}" ]] && [[ -z "${urlVariant}" ]]; then
    echo -e "url_variant_access_token specified without url_variant."
    exit 1
  fi
}

main() {
  local inputFilePath=""
  local outputFilePath=""
  local probands=""
  local pedFilePath=""
  local phenotypes=""
  local cfgFilePaths=""
  local force=0
  local keep=0

  local -r parsedArguments=$(getopt -a -n pipeline -o i:o:b:p:t:c:fkh --long input:,output:,probands:,pedigree:,phenotypes:,config:,force,keep,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  eval set -- "$parsedArguments"
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
    -p | --pedigree)
      pedFilePath=$(realpath "$2")
      shift 2
      ;;
    -t | --phenotypes)
      phenotypes="$2"
      shift 2
      ;;
    -c | --config)
      cfgFilePaths="$2"
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

  if [[ -z "${inputFilePath}" ]]; then
    echo -e "missing required option -i or --input."
    echo -e "try bash '${SCRIPT_NAME} -h or --help' for more information."
    exit 1
  fi

  local maxRecords=""
  local maxSamples=""
  local templateFilePath=""
  local urlReference=""
  local urlReferenceAccessToken=""
  local urlAlignment=""
  local urlAlignmentAccessToken=""
  local urlVariant=""
  local urlVariantAccessToken=""

  local parseCfgFilePaths="${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePaths}" ]]; then
    parseCfgFilePaths="${parseCfgFilePaths},${cfgFilePaths}"
  fi
  parseCfgs "${parseCfgFilePaths}"

  if [[ -n "${VIP_CFG_MAP["report_max_records"]+unset}" ]]; then
    maxRecords="${VIP_CFG_MAP["report_max_records"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["report_max_samples"]+unset}" ]]; then
    maxSamples="${VIP_CFG_MAP["report_max_samples"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["report_template"]+unset}" ]]; then
    templateFilePath="${VIP_CFG_MAP["report_template"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["url_reference"]+unset}" ]]; then
    urlReference="${VIP_CFG_MAP["url_reference"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["url_reference_access_token"]+unset}" ]]; then
    urlReferenceAccessToken="${VIP_CFG_MAP["url_reference_access_token"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["url_alignment"]+unset}" ]]; then
    urlAlignment="${VIP_CFG_MAP["url_alignment"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["url_alignment_access_token"]+unset}" ]]; then
    urlAlignmentAccessToken="${VIP_CFG_MAP["url_alignment_access_token"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["url_variant"]+unset}" ]]; then
    urlVariant="${VIP_CFG_MAP["url_variant"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["url_variant_access_token"]+unset}" ]]; then
    urlVariantAccessToken="${VIP_CFG_MAP["url_variant_access_token"]}"
  fi
  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="${inputFilePath}.html"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${probands}" "${pedFilePath}" "${phenotypes}" "${force}" "${maxRecords}" "${maxSamples}" "${templateFilePath}" "${urlReference}" "${urlReferenceAccessToken}" "${urlAlignment}" "${urlAlignmentAccessToken}" "${urlVariant}" "${urlVariantAccessToken}"

  mkdir -p "$(dirname "${outputFilePath}")"
  local -r outputDir="$(realpath "$(dirname "${outputFilePath}")")"
  local -r outputFilename="$(basename "${outputFilePath}")"
  outputFilePath="${outputDir}/${outputFilename}"

  if [[ -f "${outputFilePath}" ]] && [[ "${force}" == "1" ]]; then
    rm "${outputFilePath}"
  fi

  report "${inputFilePath}" "${outputFilePath}" "${probands}" "${pedFilePath}" "${phenotypes}" "${maxRecords}" "${maxSamples}" "${templateFilePath}" "${urlReference}" "${urlReferenceAccessToken}" "${urlAlignment}" "${urlAlignmentAccessToken}" "${urlVariant}" "${urlVariantAccessToken}"
}

main "${@}"
