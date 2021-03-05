#!/bin/bash
#SBATCH --job-name=vip_filter
#SBATCH --output=vip_filter.out
#SBATCH --error=vip_filter.err
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

-c, --config     <arg>    optional: Configuration file (.cfg)
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.

config:
  filter_tree             decision tree file (.json) that applies classes 'F' and 'T'.
  cpu_cores               see pipeline.sh"
}

# arguments:
#   $1 path to decision tree file
createDefaultDecisionTree() {
  local -r treeFilePath="${1}"

  cat >"${treeFilePath}" <<EOT
{
  "rootNode": "filter",
  "nodes": {
    "filter": {
      "type": "BOOL",
      "description": "All filters passed",
      "query": {
        "field": "FILTER",
        "operator": "==",
        "value": [
          "PASS"
        ]
      },
      "outcomeTrue": {
        "nextNode": "mvl"
      },
      "outcomeFalse": {
        "nextNode": "exit_f"
      },
      "outcomeMissing": {
        "nextNode": "mvl"
      }
    },
    "mvl": {
      "type": "CATEGORICAL",
      "description": "Managed Variant List classification",
      "field": "INFO/VKGL_UMCG",
      "outcomeMap": {
        "P": {
          "nextNode": "exit_t"
        },
        "LP": {
          "nextNode": "exit_t"
        },
        "LB": {
          "nextNode": "exit_f"
        },
        "B": {
          "nextNode": "exit_f"
        }
      },
      "outcomeMissing": {
        "nextNode": "vkgl"
      },
      "outcomeDefault": {
        "nextNode": "vkgl"
      }
    },
    "vkgl": {
      "type": "CATEGORICAL",
      "description": "VKGL classification",
      "field": "INFO/VKGL",
      "outcomeMap": {
        "P": {
          "nextNode": "exit_t"
        },
        "LP": {
          "nextNode": "exit_t"
        },
        "LB": {
          "nextNode": "exit_f"
        },
        "B": {
          "nextNode": "exit_f"
        }
      },
      "outcomeMissing": {
        "nextNode": "capice"
      },
      "outcomeDefault": {
        "nextNode": "capice"
      }
    },
    "capice": {
      "type": "BOOL",
      "description": "CAPICE score >= 0.2",
      "query": {
        "field": "INFO/CAP",
        "operator": ">=",
        "value": 0.2
      },
      "outcomeTrue": {
        "nextNode": "consequence"
      },
      "outcomeFalse": {
        "nextNode": "exit_f"
      },
      "outcomeMissing": {
        "nextNode": "consequence"
      }
    },
    "consequence": {
      "type": "BOOL",
      "description": "CSQ annotation exists",
      "query": {
        "field": "INFO/CSQ/SYMBOL",
        "operator": "!=",
        "value": "DUMMY_SYMBOL"
      },
      "outcomeTrue": {
        "nextNode": "gnomad"
      },
      "outcomeFalse": {
        "nextNode": "exit_f"
      },
      "outcomeMissing": {
        "nextNode": "exit_f"
      }
    },
    "gnomad": {
      "type": "BOOL",
      "description": "gnomAD_AF < 0.02",
      "query": {
        "field": "INFO/CSQ/gnomAD_AF",
        "operator": "<",
        "value": 0.02
      },
      "outcomeTrue": {
        "nextNode": "exit_t"
      },
      "outcomeFalse": {
        "nextNode": "exit_f"
      },
      "outcomeMissing": {
        "nextNode": "exit_t"
      }
    },
    "exit_t": {
      "type": "LEAF",
      "class": "T"
    },
    "exit_f": {
      "type": "LEAF",
      "class": "F"
    }
  }
}
EOT
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 path to decision tree file (optional)
classify() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local treeFilePath="${3}"

  module load "${MOD_VCF_DECISION_TREE}"

  if [ -z "${treeFilePath}" ]; then
    treeFilePath="$(dirname "${outputFilePath}")"/decision-tree.json
    createDefaultDecisionTree "${treeFilePath}"
  fi

  local args=()
  args+=("-Djava.io.tmpdir=${TMPDIR}")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "${EBROOTVCFMINDECISIONMINTREE}/vcf-decision-tree.jar")
  args+=("-i" "${inputFilePath}")
  args+=("-c" "${treeFilePath}")
  args+=("-o" "${outputFilePath}")

  java "${args[@]}"

  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 number of threads
filter() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r threads="${3}"

  module load "${MOD_BCF_TOOLS}"

  local args=()
  args+=("filter")
  args+=("-i" "VIPC==\"T\"")
  args+=("-o" "${outputFilePath}")
  args+=("-O" "z")
  args+=("--no-version")
  args+=("--threads" "${threads}")
  args+=("${inputFilePath}")

  bcftools "${args[@]}"

  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 force
#   $4 cpu cores
#   $5 path to tree file
validate() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r force="${3}"
  local -r cpuCores="${4}"
  local -r treeFilePath="${5}"

  if ! validateInputPath "${inputFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if ! validateOutputPath "${outputFilePath}" "${force}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  #TODO validate cpu cores

  if [[ -n "${treeFilePath}" ]] && [[ ! -f "${treeFilePath}" ]]; then
    echo -e "tree ${treeFilePath} does not exist."
    exit 1
  fi
}

main() {
  local -r parsedArguments=$(getopt -a -n pipeline -o i:o:c:fk --long input:,output:,config:,force,keep -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local inputFilePath=""
  local outputFilePath=""
  local cfgFilePath=""
  local force=0
  local keep=0

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
    -c | --config)
      cfgFilePath="$2"
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
  local treeFilePath=""

  parseCfg "${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePath}" ]]; then
    parseCfg "${cfgFilePath}"
  fi
  if [[ -n "${VIP_CFG_MAP["cpu_cores"]+unset}" ]]; then
    cpuCores=${VIP_CFG_MAP["cpu_cores"]}
  fi
  if [[ -n "${VIP_CFG_MAP["filter_tree"]+unset}" ]]; then
    treeFilePath=${VIP_CFG_MAP["filter_tree"]}
  fi

  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="$(createOutputPathFromPostfix "${inputFilePath}" "vip_filter")"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${force}" "${cpuCores}" "${treeFilePath}"

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

  # step 1: classify
  currentOutputDir="${workDir}/1_classify"
  currentOutputFilePath="${currentOutputDir}/${outputFilename}"
  mkdir -p "${currentOutputDir}"
  classify "${currentInputFilePath}" "${currentOutputFilePath}" "${treeFilePath}"
  currentInputFilePath="${currentOutputFilePath}"

  # step 2: filter based on classification
  filter "${currentInputFilePath}" "${outputFilePath}" "${cpuCores}"
}

main "${@}"
