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

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [ -n "$SLURM_JOB_ID" ]; then SCRIPT_DIR=$(dirname $(scontrol show job "$SLURM_JOBID" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)); else SCRIPT_DIR=$(dirname $(realpath "$0")); fi

# shellcheck source=utils/header.sh
source "${SCRIPT_DIR}"/utils/header.sh

INPUT=""
OUTPUT=""
TREE=""
CPU_CORES=4
FORCE=0

usage()
{
  echo "usage: pipeline_filter.sh -i <arg> -o <arg> [-f]

-i,  --input   <arg>       required: Input VCF file (.vcf or .vcf.gz).
-o,  --output  <arg>       required: Output VCF file (.vcf or .vcf.gz).
-t,  --tree    <arg>       optional: Decision tree file (.json) that applies classes 'F' and 'T'.
-c,  --cpu_cores           optional: Number of CPU cores available for this process. Default: 4
-f,  --force               optional: Override the output file if it already exists.

examples:
  pipeline_filter.sh -i in.vcf -o out.vcf
  pipeline_filter.sh -i in.vcf.gz -o out.vcf.gz -c 2 -f"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:t:c:f --long input:,output:,tree:,cpu_cores:,force -- "$@")
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
    -t | --tree)
      TREE=$(realpath "$2")
      shift 2
      ;;
    -f | --force)
      FORCE=1
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

# vcf-decision-tree
DECISION_TREE_INPUT="${INPUT}"
if [ -z "${TREE}" ]
then
  DECISION_TREE_CONF="${OUTPUT_DIR_ABSOLUTE}"/decision-tree.json
  cat > "${DECISION_TREE_CONF}" << EOT
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
else
  DECISION_TREE_CONF="${TREE}"
fi
DECISION_TREE_OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/classified.vcf.gz

DECISION_TREE_ARGS=("-i" "${DECISION_TREE_INPUT}" "-c" "${DECISION_TREE_CONF}" "-o" "${DECISION_TREE_OUTPUT}")
if [ "${FORCE}" == "1" ]
then
  DECISION_TREE_ARGS+=("-f")
fi
if [ -z "${TMPDIR+x}" ]; then
	TMPDIR=/tmp
fi

module load "${MOD_VCF_DECISION_TREE}"
java -Djava.io.tmpdir="${TMPDIR}" -XX:ParallelGCThreads=2 -jar "${EBROOTVCFMINDECISIONMINTREE}"/vcf-decision-tree.jar "${DECISION_TREE_ARGS[@]}"
module purge

# bcftools filter
BCFTOOLS_FILTER_INPUT="${DECISION_TREE_OUTPUT}"
BCFTOOLS_FILTER_OUTPUT="${OUTPUT}"
BCFTOOLS_FILTER_ARGS=("--threads" "${CPU_CORES}" "${BCFTOOLS_FILTER_INPUT}")

module load "${MOD_BCF_TOOLS}"
module load "${MOD_HTS_LIB}"
if [[ "${BCFTOOLS_FILTER_OUTPUT}" == *.vcf.gz ]]
then
	bcftools filter -i'VIPC=="T"' "${BCFTOOLS_FILTER_ARGS[@]}" | bgzip -c > "${BCFTOOLS_FILTER_OUTPUT}"
else
	bcftools filter -i'VIPC=="T"' "${BCFTOOLS_FILTER_ARGS[@]}" > "${BCFTOOLS_FILTER_OUTPUT}"
fi
module purge