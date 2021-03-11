#!/bin/bash
#SBATCH --job-name=vip
#SBATCH --outputFilePath=vip.out
#SBATCH --error=vip.err
#SBATCH --time=05:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16gb
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
-h, --help                optional: Print this message and exit.

config:
  assembly                allowed values: GRCh37, GRCh38 default: GRCh37
  reference               reference sequence file
  cpu_cores               number of CPU cores
  preprocess_*            see 'bash pipeline_preprocess.sh --help' for usage.
  annotate_*              see 'bash pipeline_annotate.sh --help' for usage.
  filter_*                see 'bash pipeline_filter.sh --help' for usage.
  inheritance_*           see 'bash pipeline_inheritance.sh --help' for usage.
  report_*                see 'bash pipeline_report.sh --help' for usage.

examples:
  ${SCRIPT_NAME} -i in.vcf
  ${SCRIPT_NAME} -i in.vcf.gz -o out.vcf.gz
  ${SCRIPT_NAME} -i in.vcf.gz -b sample0 -p in.ped -t HP:0000123 -s inheritance
  ${SCRIPT_NAME} -i in.vcf.gz -c config.cfg -f -k

examples - probands:
  ${SCRIPT_NAME} -i in.vcf.gz --probands sample0
  ${SCRIPT_NAME} -i in.vcf.gz --probands sample0,sample1

examples - phenotypes:
  ${SCRIPT_NAME} -i in.vcf.gz --phenotypes HP:0000123
  ${SCRIPT_NAME} -i in.vcf.gz --phenotypes HP:0000123;HP:0000234
  ${SCRIPT_NAME} -i in.vcf.gz --phenotypes sample0/HP:0000123
  ${SCRIPT_NAME} -i in.vcf.gz --phenotypes sample0/HP:0000123,sample1/HP:0000234"
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 comma-separated proband identifiers (optional)
#   $4 path to pedigree file (optional)
#   $5 phenotypes (optional)
#   $6 force
#   $7 cpu cores
validate() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r probands="${3}"
  local -r pedFilePath="${4}"
  local -r phenotypes="${5}"
  local -r force="${6}"
  local -r cpuCores="${7}"

  if ! validateInputPath "${inputFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if ! validateOutputPath "${outputFilePath}" "${force}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if [[ "${force}" == "0" ]] && [[ -f "${outputFilePath}.html" ]]; then
    echo -e "output report ${outputFilePath}.html already exists, use -f to overwrite."
    exit 1
  fi

  if [[ -n "${probands}" ]] && ! containsProbands "${probands}" "${inputFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if [[ -n "${pedFilePath}" ]] && [[ ! -f "${pedFilePath}" ]]; then
    echo -e "pedigree ${pedFilePath} does not exist."
    exit 1
  fi

  if [[ -n "${phenotypes}" ]]; then
    #TODO validate phenotypes
    :
  fi

  #TODO validate cpu cores
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 pipeline arguments
#   $4 number of threads
annotatePipelineVersionAndCommand() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r pipelineArgs="${3}"
  local -r threads="${4}"

  local args=()
  args+=("annotate")
  args+=("-h" "-")
  args+=("-O" "z")
  args+=("-o" "${outputFilePath}")
  args+=("--no-version")
  args+=("--threads" "${threads}")
  args+=("${inputFilePath}")

  module load "${MOD_BCF_TOOLS}"
  printf "##VIP_Version=%s\n##VIP_Command=%s" "${VIP_VERSION}" "${pipelineArgs}" | bcftools "${args[@]}"
  module purge
}

# arguments:
#   $1 path to inputFilePath file
#   $2 path to outputFilePath file
#   $3 comma-separated proband identifiers (optional)
#   $4 path to cfgFilePath file (optional)
#   $5 force
#   $6 keep
preprocess() {
  local -r inputPath="${1}"
  local -r outputPath="${2}"
  local -r probands="${3}"
  local -r configPath="${4}"
  local -r force="${5}"
  local -r keep="${6}"

  local args=()
  args+=("-i" "${inputPath}")
  args+=("-o" "${outputPath}")
  if [[ -n "${probands}" ]]; then
    args+=("-b" "${probands}")
  fi
  if [[ -n "${configPath}" ]]; then
    args+=("-c" "${configPath}")
  fi
  if [[ "${force}" == "1" ]]; then
    args+=("-f")
  fi
  if [[ "${keep}" == "1" ]]; then
    args+=("-k")
  fi
  bash "${SCRIPT_DIR}"/pipeline_preprocess.sh "${args[@]}"
}

# arguments:
#   $1 path to inputFilePath file
#   $2 path to outputFilePath file
#   $3 phenotypes (optional)
#   $4 path to cfgFilePath file (optional)
#   $5 force
#   $6 keep
annotate() {
  local -r inputPath="${1}"
  local -r outputPath="${2}"
  local -r phenotypes="${3}"
  local -r configPath="${4}"
  local -r force="${5}"
  local -r keep="${6}"

  local args=()
  args+=("-i" "${inputPath}")
  args+=("-o" "${outputPath}")
  args+=("-t" "${phenotypes}")
  if [[ -n "${configPath}" ]]; then
    args+=("-c" "${configPath}")
  fi
  if [[ "${force}" == "1" ]]; then
    args+=("-f")
  fi
  if [[ "${keep}" == "1" ]]; then
    args+=("-k")
  fi

  bash "${SCRIPT_DIR}"/pipeline_annotate.sh "${args[@]}"
}

# arguments:
#   $1 path to inputFilePath file
#   $2 path to outputFilePath file
#   $3 path to cfgFilePath file (optional)
#   $4 force
#   $5 keep
filter() {
  local -r inputPath="${1}"
  local -r outputPath="${2}"
  local -r configPath="${3}"
  local -r force="${4}"
  local -r keep="${5}"

  local args=()
  args+=("-i" "${inputPath}")
  args+=("-o" "${outputPath}")
  if [[ -n "${configPath}" ]]; then
    args+=("-c" "${configPath}")
  fi
  if [[ "${force}" == "1" ]]; then
    args+=("-f")
  fi
  if [[ "${keep}" == "1" ]]; then
    args+=("-k")
  fi

  bash "${SCRIPT_DIR}"/pipeline_filter.sh "${args[@]}"
}

# arguments:
#   $1 path to input file
#   $2 path to pedigree file (optional)
# returns:
#    0 if inheritance matching can't be performed
#    1 if inheritance matching can be performed
doInheritance() {
  local -r inputPath="${1}"
  local -r pedigreePath="${2}"

  if ! containsInheritanceModesGeneAnnotations "${inputPath}"; then
    echo -e "step 4/5 inheritance matching skipped: input is missing inheritance modes for gene symbols."
    return 1
  elif [[ -z "${pedigreePath}" ]]; then
    echo -e "step 4/5 inheritance matching skipped: pedigree not provided."
    return 1
  else
    return 0
  fi
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 comma-separated proband identifiers (optional)
#   $4 path to pedigree file
#   $5 path to config file (optional)
#   $6 force
#   $7 keep
inheritance() {
  local -r inputPath="${1}"
  local -r outputPath="${2}"
  local -r probands="${3}"
  local -r pedigreePath="${4}"
  local -r configPath="${5}"
  local -r force="${6}"
  local -r keep="${7}"

  local args=()
  args+=("-i" "${inputPath}")
  args+=("-o" "${outputPath}")
  args+=("-p" "${pedigreePath}")
  if [[ -n "${probands}" ]]; then
    args+=("-b" "${probands}")
  fi
  if [[ -n "${configPath}" ]]; then
    args+=("-c" "${configPath}")
  fi
  if [[ "${force}" == "1" ]]; then
    args+=("-f")
  fi
  if [[ "${keep}" == "1" ]]; then
    args+=("-k")
  fi

  bash "${SCRIPT_DIR}"/pipeline_inheritance.sh "${args[@]}"
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 comma-separated proband identifiers (optional)
#   $4 path to pedigree file (optional)
#   $5 phenotypes (optional)
#   $6 path to config file (optional)
#   $7 force
#   $8 keep
report() {
  local -r inputPath="${1}"
  local -r outputPath="${2}"
  local -r probands="${3}"
  local -r pedigreePath="${4}"
  local -r phenotypes="${5}"
  local -r configPath="${6}"
  local -r force="${7}"
  local -r keep="${8}"

  local args=()
  args+=("-i" "${inputPath}")
  args+=("-o" "${outputPath}")
  if [[ -n "${probands}" ]]; then
    args+=("-b" "${probands}")
  fi
  if [[ -n "${pedigreePath}" ]]; then
    args+=("-p" "${pedigreePath}")
  fi
  if [[ -n "${phenotypes}" ]]; then
    args+=("-t" "${phenotypes}")
  fi
  if [[ -n "${configPath}" ]]; then
    args+=("-c" "${configPath}")
  fi
  if [[ "${force}" == "1" ]]; then
    args+=("-f")
  fi
  if [[ "${keep}" == "1" ]]; then
    args+=("-k")
  fi

  bash "${SCRIPT_DIR}"/pipeline_report.sh "${args[@]}"
}

main() {
  local -r arguments="$(printf ' %q' "$@")"
  local -r parsedArguments=$(getopt -a -n pipeline -o i:o:b:p:t:s:c:fkh --long input:,output:,probands:,pedigree:,phenotypes:,start:,config:,force,keep,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local inputFilePath=""
  local outputFilePath=""
  local probands=""
  local pedFilePath=""
  local phenotypes=""
  local start=0
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
    -p | --pedigree)
      pedFilePath=$(realpath "$2")
      shift 2
      ;;
    -t | --phenotypes)
      phenotypes="$2"
      shift 2
      ;;
    -s | --start)
      case $2 in
      preprocess)
        start=1
        ;;
      annotate)
        start=2
        ;;
      filter)
        start=3
        ;;
      inheritance)
        start=4
        ;;
      report)
        start=5
        ;;
      *)
        echo -e "Unknown step '$2' in -s."
        usage
        exit 2
        ;;
      esac

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
    echo -e "try bash '${SCRIPT_NAME} -h or --help' for more information."
    exit 1
  fi

  local cpuCores=""

  parseCfg "${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePath}" ]]; then
    parseCfg "${cfgFilePath}"
  fi
  if [[ -n "${VIP_CFG_MAP["cpu_cores"]+unset}" ]]; then
    cpuCores="${VIP_CFG_MAP["cpu_cores"]}"
  fi

  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="$(createOutputPathFromPostfix "${inputFilePath}" "vip")"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${probands}" "${pedFilePath}" "${phenotypes}" "${cfgFilePath}" "${cpuCores}"

  mkdir -p "$(dirname "${outputFilePath}")"
  local -r outputDir="$(realpath "$(dirname "${outputFilePath}")")"
  local -r outputFilename="$(basename "${outputFilePath}")"
  outputFilePath="${outputDir}/${outputFilename}"

  if [[ -f "${outputFilePath}" ]] && [[ "${force}" == "1" ]]; then
    rm "${outputFilePath}"
  fi

  initWorkDir "${outputFilePath}" "${force}" "${keep}"
  local -r baseWorkDir="${VIP_WORK_DIR}"

  local currentInput="${inputFilePath}" currentOutput startTime elapsedTime
  if [[ "$start" -le 1 ]]; then
    echo -e "step 1/5 preprocessing ..."
    startTime="${SECONDS}"

    VIP_WORK_DIR="${baseWorkDir}/1_preprocess"
    currentOutput="${VIP_WORK_DIR}/${outputFilename}"
    preprocess "${currentInput}" "${currentOutput}" "${probands}" "${cfgFilePath}" "${force}" "${keep}"
    currentInput="${currentOutput}"

    elapsedTime=$((SECONDS - startTime))
    echo -e "step 1/5 preprocessing completed in $((elapsedTime / 60))m$((elapsedTime % 60))s"
  fi

  if [[ "$start" -le 2 ]]; then
    echo -e "step 2/5 annotating ..."
    startTime="${SECONDS}"

    VIP_WORK_DIR="${baseWorkDir}/2_annotate"
    currentOutput="${VIP_WORK_DIR}/${outputFilename}"
    annotate "${currentInput}" "${currentOutput}" "${phenotypes}" "${cfgFilePath}" "${force}" "${keep}"
    currentInput="${currentOutput}"

    elapsedTime=$((SECONDS - startTime))
    echo -e "step 2/5 annotating completed in $((elapsedTime / 60))m$((elapsedTime % 60))s"
  fi

  if [[ "$start" -le 3 ]]; then
    echo -e "step 3/5 filtering ..."
    startTime="${SECONDS}"

    VIP_WORK_DIR="${baseWorkDir}/3_filter"
    currentOutput="${VIP_WORK_DIR}/${outputFilename}"
    filter "${currentInput}" "${currentOutput}" "${cfgFilePath}" "${force}" "${keep}"
    currentInput="${currentOutput}"

    elapsedTime=$((SECONDS - startTime))
    echo -e "step 3/5 filtering completed in $((elapsedTime / 60))m$((elapsedTime % 60))s"
  fi

  if [[ "$start" -le 4 ]]; then
    if doInheritance "${currentInput}" "${pedFilePath}"; then
      echo -e "step 4/5 inheritance matching ..."
      startTime="${SECONDS}"

      VIP_WORK_DIR="${baseWorkDir}/4_inheritance"
      currentOutput="${VIP_WORK_DIR}/${outputFilename}"
      inheritance "${currentInput}" "${currentOutput}" "${probands}" "${pedFilePath}" "${cfgFilePath}" "${force}" "${keep}"
      currentInput="${currentOutput}"

      elapsedTime=$((SECONDS - startTime))
      echo -e "step 4/5 inheritance matching completed in $((elapsedTime / 60))m$((elapsedTime % 60))s"
    fi
  fi

  echo -e "step 5/5 reporting ..."
  startTime="${SECONDS}"

  currentOutput="${outputFilePath}"
  annotatePipelineVersionAndCommand "${currentInput}" "${currentOutput}" "${arguments}" "${cpuCores}"
  currentInput="${currentOutput}"

  VIP_WORK_DIR="${baseWorkDir}/5_report"
  local -r outputReportFilePath="${outputFilePath}.html"
  report "${currentInput}" "${outputReportFilePath}" "${probands}" "${pedFilePath}" "${phenotypes}" "${cfgFilePath}" "${force}" "${keep}"

  elapsedTime=$((SECONDS - startTime))
  echo -e "step 5/5 reporting completed in $((elapsedTime / 60))m$((elapsedTime % 60))s"

  echo -e "done"
  echo -e "created output: ${outputFilePath}"
  echo -e "created report: ${outputReportFilePath}"
}

main "${@}"
