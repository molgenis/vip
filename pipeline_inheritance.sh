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

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [ -n "$SLURM_JOB_ID" ]; then SCRIPT_DIR=$(dirname $(scontrol show job "$SLURM_JOBID" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)); else SCRIPT_DIR=$(dirname $(realpath "$0")); fi

# shellcheck source=utils/header.sh
source "${SCRIPT_DIR}"/utils/header.sh

INPUT=""
OUTPUT=""
PEDIGREE=""
PROBANDS=""
CPU_CORES=4
FORCE=0

usage()
{
  echo "usage: pipeline_inheritance.sh -i <arg> [-p <arg>] [-b <arg>] -o <arg> [-c <arg>] [-f]

-i,  --input   <arg>       required: Input VCF file (.vcf or .vcf.gz).
-p,  --pedigree <arg>      required: Pedigree file (.ped).
-b,  --probands <arg>      optional: Subjects being reported on (comma-separated VCF sample names).
-o,  --output  <arg>       required: Output VCF file (.vcf or .vcf.gz).
-c,  --cpu_cores           optional: Number of CPU cores available for this process. Default: 4
-f,  --force               optional: Override the output file if it already exists.

examples:
  pipeline_inheritance.sh -i in.vcf -p in.ped -o out.vcf
  pipeline_inheritance.sh -i in.vcf.gz -p in.ped -b Patient -o out.vcf.gz -c 2 -f"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:p:b:o:c:f --long input:,ped:,probands:,output:,cpu_cores:,force -- "$@")
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
    -p | --ped)
      PEDIGREE=$(realpath "$2")
      shift 2
      ;;
    -b | --probands)
      PROBANDS="$2"
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
if [ -z "${PEDIGREE}" ]
then
  echo -e "missing required option -p\n"
	usage
	exit 2
fi
if [ ! -f "${PEDIGREE}" ]
then
	echo -e "$PEDIGREE does not exist.\n"
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

module load "${MOD_BCF_TOOLS}"

SPLIT_VEP_ARGS=("-c" "Gene" "${INPUT}")
if [[ "${INPUT}" == *.vcf.gz ]]
then
  SPLIT_VEP_OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/splitted.vcf.gz
	SPLIT_VEP_ARGS+=("-O" "z")
else
  SPLIT_VEP_OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/splitted.vcf
fi
bcftools +split-vep "${SPLIT_VEP_ARGS[@]}" > "${SPLIT_VEP_OUTPUT}"

module purge

module load "${MOD_PYTHON_PLUS}"
GENMOD_OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/genmod.vcf

GENMOD_ARGS=("${SPLIT_VEP_OUTPUT}" "-f" "${PEDIGREE}" "-k" "Gene" "-p" "${CPU_CORES}")
genmod models "${GENMOD_ARGS[@]}" > "${GENMOD_OUTPUT}"

module purge

module load "${MOD_VCF_INHERITANCE_MATCHER}"
INHERITANCE_OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/inheritance.vcf.gz
INHERITANCE_ARGS=("-i" "${GENMOD_OUTPUT}" "-pd" "${PEDIGREE}" "-o" "${INHERITANCE_OUTPUT}")
if [ -n "${PROBANDS}" ]; then
	INHERITANCE_ARGS+=("-pb" "${PROBANDS}")
fi
if [ "${FORCE}" == "1" ]
then
  INHERITANCE_ARGS+=("-f")
fi
if [ -z "${TMPDIR+x}" ]; then
	TMPDIR=/tmp
fi
java -Djava.io.tmpdir="${TMPDIR}" -XX:ParallelGCThreads=2 -jar "${EBROOTVCFMININHERITANCEMINMATCHER}"/vcf-inheritance-matcher.jar "${INHERITANCE_ARGS[@]}"
module purge

module load "${MOD_BCF_TOOLS}"
INH_BCFTOOLS_REMOVE_ARGS=("annotate" "-x" "INFO/Gene,INFO/Compounds,INFO/GeneticModels,INFO/ModelScore")
if [[ "${OUTPUT}" == *.vcf.gz ]]
then
  INH_REMOVE_ANN_OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/remove_annotations.vcf.gz
	INH_BCFTOOLS_REMOVE_ARGS+=("-O" "z")
else
  INH_REMOVE_ANN_OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/remove_annotations.vcf
fi
INH_BCFTOOLS_REMOVE_ARGS+=("-o" "${INH_REMOVE_ANN_OUTPUT}")
INH_BCFTOOLS_REMOVE_ARGS+=("--threads" "${CPU_CORES}" "${INHERITANCE_OUTPUT}")

echo 'removing INFO inheritance annotations ...'
bcftools "${INH_BCFTOOLS_REMOVE_ARGS[@]}"
echo 'removing INFO inheritance annotations done'

module purge;

mv "${INH_REMOVE_ANN_OUTPUT}" "${OUTPUT}"
ln -s "${OUTPUT}" "${INH_REMOVE_ANN_OUTPUT}"
