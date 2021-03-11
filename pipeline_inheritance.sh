#!/bin/bash
#SBATCH --job-name=vip_inheritance
#SBATCH --output=vip_inheritance.out
#SBATCH --error=vip_inheritance.err
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
  echo -e "usage: ${SCRIPT_NAME} -i <arg> -p <arg>

-i, --input      <arg>    required: Input VCF file (.vcf or .vcf.gz).
-o, --output     <arg>    optional: Output VCF file (.vcf.gz).
-b, --probands   <arg>    optional: Subjects being reported on (comma-separated VCF sample names).
-p, --pedigree   <arg>    required: Pedigree file (.ped).

-c, --config     <arg>    optional: Configuration file (.cfg)
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.
-h, --help                optional: Print this message and exit.

config:
  cpu_cores               see pipeline.sh"
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 path to pedigree file
#   $4 cpu cores
annotateGeneticModels() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r pedFilePath="${3}"
  local -r cpuCores="${4}"

  module load "${MOD_PYTHON_PLUS}"
  module load "${MOD_HTS_LIB}"

  args=()
  args+=("models")
  args+=("${inputFilePath}")
  args+=("-f" "${pedFilePath}")
  args+=("--vep")
  args+=("-p" "${cpuCores}")
  args+=("-r" "/apps/data/UMCG/non_penetrance/UMCG_non_penetrantie_genes_entrez_20210125.tsv")
  genmod "${args[@]}" | bgzip >"${outputFilePath}"

  module purge

}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 path to pedigree file
#   $4 probands (optional)
matchInheritance() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r pedFilePath="${3}"
  local -r probands="${4}"

  module load "${MOD_VCF_INHERITANCE_MATCHER}"

  args=()
  args+=("-Djava.io.tmpdir=${TMPDIR}")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "${EBROOTVCFMININHERITANCEMINMATCHER}/vcf-inheritance-matcher.jar")
  args+=("-i" "${inputFilePath}")
  args+=("-pd" "${pedFilePath}")
  args+=("-o" "${outputFilePath}")
  if [ -n "${probands}" ]; then
    args+=("-pb" "${probands}")
  fi

  java "${args[@]}"

  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 cpu cores
removeAnnotations() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r cpuCores="${3}"

  module load "${MOD_BCF_TOOLS}"

  args=()
  args+=("annotate")
  args+=("-x" "INFO/Compounds,INFO/GeneticModels,INFO/ModelScore")
  args+=("-O" "z")
  args+=("-o" "${outputFilePath}")
  args+=("--no-version")
  args+=("--threads" "${cpuCores}")
  args+=("${inputFilePath}")

  echo 'removing INFO inheritance annotations ...'
  bcftools "${args[@]}"
  echo 'removing INFO inheritance annotations done'

  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 comma-separated proband identifiers (optional)
#   $4 path to pedigree file
#   $5 force
#   $6 cpu cores
validate() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r probands="${3}"
  local -r pedFilePath="${4}"
  local -r force="${5}"
  local -r cpuCores="${6}"

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

  if [[ -z "${pedFilePath}" ]]; then
    echo -e "missing required option -p."
    return 1
  fi
  if [[ ! -f "${pedFilePath}" ]]; then
    echo -e "pedigree ${pedFilePath} does not exist."
    exit 1
  fi
}

main() {
  local inputFilePath=""
  local outputFilePath=""
  local probands=""
  local pedFilePath=""
  local cfgFilePath=""
  local force=0
  local keep=0

  local -r parsedArguments=$(getopt -a -n pipeline -o i:o:b:p:c:fkh --long input:,output:,probands:,pedigree:,config:,force,keep,help -- "$@")
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

  local cpuCores=""

  parseCfg "${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePath}" ]]; then
    parseCfg "${cfgFilePath}"
  fi
  if [[ -n "${VIP_CFG_MAP["cpu_cores"]+unset}" ]]; then
    cpuCores="${VIP_CFG_MAP["cpu_cores"]}"
  fi

  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="$(createOutputPathFromPostfix "${inputFilePath}" "vip_inheritance")"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${probands}" "${pedFilePath}" "${force}" "${cpuCores}"

  mkdir -p "$(dirname "${outputFilePath}")"
  local -r outputDir="$(realpath "$(dirname "${outputFilePath}")")"
  local -r outputFilename="$(basename "${outputFilePath}")"
  outputFilePath="${outputDir}/${outputFilename}"

  if [[ -f "${outputFilePath}" ]] && [[ "${force}" == "1" ]]; then
    rm "${outputFilePath}"
  fi

  initWorkDir "${outputFilePath}" "${keep}"
  local -r workDir="${VIP_WORK_DIR}"

  local currentInputFilePath="${inputFilePath}" currentOutputDir currentOutputFilePath

  # step 1: genmod
  currentOutputDir="${workDir}/1_genmod"
  currentOutputFilePath="${currentOutputDir}/${outputFilename}"
  mkdir -p "${currentOutputDir}"
  annotateGeneticModels "${currentInputFilePath}" "${currentOutputFilePath}" "${pedFilePath}" "${cpuCores}"
  currentInputFilePath="${currentOutputFilePath}"

  # step 2: inheritance matching
  currentOutputDir="${workDir}/2_match"
  currentOutputFilePath="${currentOutputDir}/${outputFilename}"
  mkdir -p "${currentOutputDir}"
  matchInheritance "${currentInputFilePath}" "${currentOutputFilePath}" "${pedFilePath}" "${probands}"
  currentInputFilePath="${currentOutputFilePath}"

  # step 3: remove INFO annotations
  removeAnnotations "${currentInputFilePath}" "${outputFilePath}" "${cpuCores}"
}

main "${@}"
