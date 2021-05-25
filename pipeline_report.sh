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

-c, --config     <arg>    optional: Comma separated list of configuration files (.cfg)
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.

config:
  report_max_records      maximum number of records in the report. Default: 100
  report_max_samples      maximum number of samples in the report. Default: 100
  report_template         HTML template to be used in the report.
  report_bams             Alignment files for samples (e.g. sample0=/path/to/0/bam,sample1=/path/to/1/bam).
  report_genes            Genes file, UCSC NCBI RefSeq format (.txt.gz). Default: UCSC NCBI RefSeq Curated for assembly GRCh37 or GRCh38
  assembly                see 'bash pipeline.sh --help' for usage.
  reference               see 'bash pipeline.sh --help' for usage."
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
#   $9  path to reference sequence file (optional)
#   $10 path to genes file (optional)
#   $11 alignment files for samples (optional)
report() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r probands="${3}"
  local -r pedFilePath="${4}"
  local -r phenotypes="${5}"
  local -r maxRecords="${6}"
  local -r maxSamples="${7}"
  local -r templateFilePath="${8}"
  local -r referenceFilePath="${9}"
  local -r genesFilePath="${10}"
  local -r sampleBamFilePaths="${11}"

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
  if [ -n "${referenceFilePath}" ]; then
    args+=("-r" "${referenceFilePath}")
  fi
  if [ -n "${genesFilePath}" ]; then
    args+=("-g" "${genesFilePath}")
  fi
  if [ -n "${sampleBamFilePaths}" ]; then
    args+=("-b" "${sampleBamFilePaths}")
  fi

  java "${args[@]}"

  module purge
}

# arguments:
#   $1  path to bam file
#   $2  path to reference sequence file
#   $3  path to vcf file
#   $4  interval padding
#   $5  path to output bam file
realignBam() {
  local -r bamFilePath="${1}"
  local -r referenceFilePath="${2}"
  local -r vcfFilePath="${3}"
  local -r intervalPadding="${4}"
  local -r outputBamFilePath="${5}"

  local -r outputVcfFilePath="${TMPDIR}/$(mktemp XXXXXXXXXX.vcf.gz)"

  if ! [[ -f "${vcfFilePath}.tbi" ]]; then
    module load "${MOD_HTS_LIB}"
    tabix -p vcf "${vcfFilePath}"
    module purge
  fi

  module load "${MOD_GATK}"

  local args=()
  args+=("--java-options" "-Djava.io.tmpdir=${TMPDIR} -XX:ParallelGCThreads=2 -Xmx4g")
  args+=("HaplotypeCaller")
  args+=("--tmp-dir" "${TMPDIR}")
  args+=("-R" "${referenceFilePath}")
  args+=("-I" "${bamFilePath}")
  args+=("-L" "${vcfFilePath}")
  args+=("-ip" "${intervalPadding}")
  args+=("--force-active")
  args+=("--dont-trim-active-regions")
  args+=("--disable-optimizations")
  args+=("-O" "${outputVcfFilePath}")
  args+=("-OVI" "false")
  args+=("-bamout" "${outputBamFilePath}")

  gatk "${args[@]}"

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
#   $10 path to reference sequence file (optional)
#   $11 path to genes file (optional)
#   $12 alignment files for samples (optional)
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
  local -r referenceFilePath="${10}"
  local -r genesFilePath="${11}"
  local -r sampleBamFilePaths="${12}"

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

  if ! validateReferencePath "${referenceFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if [[ -n "${genesFilePath}" ]] && [[ ! -f "${genesFilePath}" ]]; then
    echo -e "genes file ${genesFilePath} does not exist."
    exit 1
  fi
  if [[ -n "${genesFilePath}" ]] && ! [[ "${genesFilePath}" =~ (.+)(\.txt\.gz) ]]; then
    echo -e "genes file ${genesFilePath} is not a .txt.gz file"
    exit 1
  fi

  if ! validateSampleBamFilePaths "${inputFilePath}" "${sampleBamFilePaths}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi
}

# arguments:
#   $1 path to input file
#   $2 alignment files for samples (optional)
validateSampleBamFilePaths() {
  local -r inputFilePath="${1}"
  local -r sampleBamFilePaths="${2}"
  if [[ -z "${sampleBamFilePaths}" ]]; then
    return 0
  fi

  IFS=',' read -ra sampleBamFilePathArr <<< "${sampleBamFilePaths}"
  for sampleBamFilePathValue in "${sampleBamFilePathArr[@]}"; do
    while IFS='=' read -r key value; do
      if ! [[ -f "${value}" ]]; then
        echo -e "bam file ${value} does not exist."
        exit 1
      fi
      if ! [[ -f "${value}.bai" ]]; then
        echo -e "bam file index ${value} does not exist."
        exit 1
      fi
    done <<< "${sampleBamFilePathValue}"
  done
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

  local assembly=""
  local inputRefPath=""
  local maxRecords=""
  local maxSamples=""
  local templateFilePath=""
  local genesFilePath=""
  local sampleBamFilePaths=""

  local parseCfgFilePaths="${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePaths}" ]]; then
    parseCfgFilePaths="${parseCfgFilePaths},${cfgFilePaths}"
  fi
  parseCfgs "${parseCfgFilePaths}"

  if [[ -n "${VIP_CFG_MAP["assembly"]+unset}" ]]; then
    assembly="${VIP_CFG_MAP["assembly"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["reference"]+unset}" ]]; then
    inputRefPath="${VIP_CFG_MAP["reference"]}"
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
  if [[ -n "${VIP_CFG_MAP["report_genes"]+unset}" ]]; then
    genesFilePath="${VIP_CFG_MAP["report_genes"]}"
  elif [[ "${assembly}" == "GRCh37" ]] || [[ "${assembly}" == "GRCh38" ]]; then
    genesFilePath="${SCRIPT_DIR}/resources/genes/${assembly}/ucsc_genes_ncbi_refseq_20210519.txt.gz"
  fi
  if [[ -n "${VIP_CFG_MAP["report_bams"]+unset}" ]]; then
    sampleBamFilePaths="${VIP_CFG_MAP["report_bams"]}"
  fi

  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="${inputFilePath}.html"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${probands}" "${pedFilePath}" "${phenotypes}" "${force}" "${maxRecords}" "${maxSamples}" "${templateFilePath}" "${inputRefPath}" "${genesFilePath}" "${sampleBamFilePaths}"

  mkdir -p "$(dirname "${outputFilePath}")"
  local -r outputDir="$(realpath "$(dirname "${outputFilePath}")")"
  local -r outputFilename="$(basename "${outputFilePath}")"
  outputFilePath="${outputDir}/${outputFilename}"

  initWorkDir "${outputFilePath}" "${keep}"
  local -r workDir="${VIP_WORK_DIR}"
  mkdir -p "${workDir}"

  # realign bam files
  local realignedSampleBamFilePaths=""
  if [[ -n "${sampleBamFilePaths}" ]] && [[ -n "${inputRefPath}" ]]; then
    local realignedSampleBamFilePathArr=()

    IFS=',' read -ra sampleBamFilePathArr <<< "${sampleBamFilePaths}"
    local outputBamFile
    for sampleBamFilePathValue in "${sampleBamFilePathArr[@]}"; do
      while IFS='=' read -r key value; do
        outputBamFile="${workDir}/$(basename "${value}")"
        realignBam "${value}" "${inputRefPath}" "${inputFilePath}" "250" "${outputBamFile}"
        mv "${outputBamFile/.bam/.bai}" "${outputBamFile}.bai"
        realignedSampleBamFilePathArr+=("${key}=${outputBamFile}")
      done <<< "${sampleBamFilePathValue}"
    done

    realignedSampleBamFilePaths=$(joinArr "," "${realignedSampleBamFilePathArr[@]}")
  fi

  if [[ -f "${outputFilePath}" ]] && [[ "${force}" == "1" ]]; then
    rm "${outputFilePath}"
  fi

  report "${inputFilePath}" "${outputFilePath}" "${probands}" "${pedFilePath}" "${phenotypes}" "${maxRecords}" "${maxSamples}" "${templateFilePath}" "${inputRefPath}" "${genesFilePath}" "${realignedSampleBamFilePaths}"
}

main "${@}"
