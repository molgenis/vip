#!/bin/bash
#SBATCH --job-name=vip
#SBATCH --output=vip.out
#SBATCH --error=vip.err
#SBATCH --time=05:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16gb
#SBATCH --nodes=1
#SBATCH --export=NONE
#SBATCH --get-user-env=L60

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [ -n "$SLURM_JOB_ID" ]; then SCRIPT_DIR=$(dirname $(scontrol show job "$SLURM_JOBID" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)); else SCRIPT_DIR=$(dirname $(realpath "$0")); fi

# shellcheck source=utils/header.sh
source "${SCRIPT_DIR}"/utils/header.sh
# shellcheck source=utils/utils.sh
source "${SCRIPT_DIR}"/utils/utils.sh

INPUT=""
INPUT_REF=""
INPUT_PROBANDS=""
INPUT_PED=""
INPUT_PHENO=""
OUTPUT=""
ANN_VEP=""
ADDITONAL_ARGS_PREPROCESS=""
ADDITONAL_ARGS_REPORT=""
FLT_TREE=""
FORCE=0
KEEP=0
ASSEMBLY=GRCh37
CPU_CORES=4

usage()
{
  echo "usage: pipeline.sh -i <arg> -o <arg>

-i,  --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o,  --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-r,  --reference <arg>     optional: Reference sequence FASTA file (.fasta or .fasta.gz).
-b,  --probands <arg>      optional: Subjects being reported on (comma-separated VCF sample names).
-p,  --pedigree <arg>      optional: Pedigree file (.ped).
-t,  --phenotypes <arg>    optional: Phenotypes for input samples (see examples).
-f,  --force               optional: Override the output file if it already exists.
-k,  --keep                optional: Keep intermediate files.

--ann_vep                  optional: Variant Effect Predictor (VEP) options.
--args_preprocess          optional: Additional preprocessing module arguments.
--args_report              optional: Additional report module options for --args.
--flt_tree                 optional: Decision tree file (.json) that applies classes 'F' and 'T'.

examples:
  pipeline.sh -i in.vcf -o out.vcf
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -b sample0
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -p in.ped
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123;HP:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123,sample1/HP:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz --ann_vep "--refseq --exclude_predicted --use_given_ref"
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz -b sample0,sample1 -p in.ped -t sample0/HP:0000123;HP:0000234,sample1/HP:0000345 --ann_vep "--refseq --exclude_predicted --use_given_ref" --flt_tree custom_tree.json --args_report \"--max_samples 10\" --args_preprocess \"--filter_read_depth -1\" -f -k"
}

ARGUMENTS="$(printf ' %q' "$@")"
PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:r:b:p:t:fk --long input:,output:,reference:,probands:,pedigree:,phenotypes:,force,keep,ann_vep:,args_preprocess:,args_report:,flt_tree: -- "$@")
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
    -r | --reference)
      INPUT_REF=$(realpath "$2")
      shift 2
      ;;
    -b | --probands)
      INPUT_PROBANDS="$2"
      shift 2
      ;;
    -p | --pedigree)
      INPUT_PED=$(realpath "$2")
      shift 2
      ;;
    -t | --phenotypes)
      INPUT_PHENO="$2"
      shift 2
      ;;
    --args_preprocess)
      ADDITONAL_ARGS_PREPROCESS="$2"
      shift 2
      ;;
    --args_report)
      ADDITONAL_ARGS_REPORT="$2"
      shift 2
      ;;
    --ann_vep)
      ANN_VEP="$2"
      shift 2
      ;;
    --flt_tree)
      FLT_TREE="$2"
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
if [ -f "${OUTPUT}".html ]
then
  if [ "${FORCE}" == "1" ]
  then
    rm "${OUTPUT}".html
  else
    echo -e "${OUTPUT}.html already exists, use -f to overwrite.\n"
    exit 2
  fi
fi
if ! containsProbands "${INPUT_PROBANDS}" "${INPUT}"; then
  exit 2
fi
if [ ! -z ${INPUT_PED} ] && [ ! -f "${INPUT_PED}" ]
then
  echo -e "${INPUT_PED} does not exist.\n"
  exit 2
fi
if [ ! -z ${INPUT_REF} ] && [ ! -f "${INPUT_REF}" ]
then
  echo -e "${INPUT_REF} does not exist.\n"
  exit 2
fi
if [[ "${OUTPUT}" == *.vcf.gz ]]
then
  OUTPUT_FILENAME=$(basename "${OUTPUT}" .vcf.gz)
else
  OUTPUT_FILENAME=$(basename "${OUTPUT}" .vcf)
fi
OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/${OUTPUT_FILENAME}_pipeline_out

if [ -d "$OUTPUT_DIR" ]
then
  if [ "$FORCE" == "1" ]
  then
    rm -R "$OUTPUT_DIR"
  else
    echo -e "$OUTPUT_DIR already exists, use -f to overwrite.\n"
    exit 2
  fi
fi

mkdir -p "${OUTPUT_DIR}"

echo "step 1/5 preprocessing ..."
START_TIME=$SECONDS
PREPROCESS_OUTPUT_DIR="${OUTPUT_DIR}"/step0_preprocess
mkdir -p "${PREPROCESS_OUTPUT_DIR}"
PREPROCESS_OUTPUT="${PREPROCESS_OUTPUT_DIR}/${OUTPUT_FILE}"
PREPROCESS_ARGS=("-i" "${INPUT}" "-o" "${PREPROCESS_OUTPUT}" "--filter_low_qual" "-c" "${CPU_CORES}")
if [ -n "${INPUT_REF}" ]; then
        PREPROCESS_ARGS+=("-r" "${INPUT_REF}")
fi
if [ -n "${INPUT_PROBANDS}" ]; then
        PREPROCESS_ARGS+=("-b" "${INPUT_PROBANDS}")
fi
if [ "${FORCE}" == "1" ]; then
        PREPROCESS_ARGS+=("-f")
fi
if [ "${KEEP}" == "1" ]; then
        PREPROCESS_ARGS+=("-k")
fi
if [ -n "${ADDITONAL_ARGS_PREPROCESS}" ]; then
	PREPROCESS_ARGS+=(${ADDITONAL_ARGS_PREPROCESS})
fi
bash "${SCRIPT_DIR}"/pipeline_preprocess.sh "${PREPROCESS_ARGS[@]}"
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 1/5 preprocessing completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

echo "step 2/5 annotating ..."
START_TIME=$SECONDS
ANNOTATE_OUTPUT_DIR="${OUTPUT_DIR}"/step2_annotate/
mkdir -p "${ANNOTATE_OUTPUT_DIR}"
ANNOTATE_OUTPUT="${ANNOTATE_OUTPUT_DIR}/${OUTPUT_FILE}"
ANNOTATE_ARGS=("-i" "${PREPROCESS_OUTPUT}" "-o" "${ANNOTATE_OUTPUT}" "-c" "${CPU_CORES}" "-a" "${ASSEMBLY}")
if [ -n "${INPUT_REF}" ]; then
	ANNOTATE_ARGS+=("-r" "${INPUT_REF}")
fi
if [ "${KEEP}" == "1" ]; then
	ANNOTATE_ARGS+=("-k")
fi
if [ "${FORCE}" == "1" ]; then
  ANNOTATE_ARGS+=("-f")
fi
if [ -n "${ANN_VEP}" ]; then
  ANNOTATE_ARGS+=("--ann_vep" "${ANN_VEP}")
fi
bash "${SCRIPT_DIR}"/pipeline_annotate.sh "${ANNOTATE_ARGS[@]}"

ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 2/5 annotating completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

echo "step 3/5 filtering ..."
START_TIME=$SECONDS
FILTER_OUTPUT_DIR="${OUTPUT_DIR}"/step3_filter/
mkdir -p "${FILTER_OUTPUT_DIR}"
FILTER_OUTPUT="${FILTER_OUTPUT_DIR}/${OUTPUT_FILE}"
FILTER_ARGS=("-i" "${ANNOTATE_OUTPUT}" "-o" "${FILTER_OUTPUT}" "-c" "${CPU_CORES}")
if [ "${FORCE}" == "1" ]; then
	FILTER_ARGS+=("-f")
fi
if [ -n "${FLT_TREE}" ]; then
  FILTER_ARGS+=("--tree" "${FLT_TREE}")
fi
bash "${SCRIPT_DIR}"/pipeline_filter.sh "${FILTER_ARGS[@]}"

ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 3/5 filtering completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

echo "step 4/5 inheritance matching ..."
START_TIME=$SECONDS
module load "${MOD_BCF_TOOLS}"
HEADER=$(bcftools view -h "${FILTER_OUTPUT}")
if echo "$HEADER" | grep -q "##InheritanceModesGene"; then
  if [ -z "${INPUT_PED}" ]
  then
    echo "skipping inheritance matching: no PED file provided."
    INHERITANCE_OUTPUT="${FILTER_OUTPUT}"
  else
    INHERITANCE_OUTPUT_DIR="${OUTPUT_DIR}"/step4_inheritance/
    mkdir -p "${INHERITANCE_OUTPUT_DIR}"
    INHERITANCE_OUTPUT="${INHERITANCE_OUTPUT_DIR}/${OUTPUT_FILE}"
    INHERITANCE_ARGS=("-i" "${FILTER_OUTPUT}" "-o" "${INHERITANCE_OUTPUT}" "-p" "${INPUT_PED}" "-c" "${CPU_CORES}")
    if [ "${FORCE}" == "1" ]; then
      INHERITANCE_ARGS+=("-f")
    fi
    if [ -n "${INPUT_PROBANDS}" ]; then
      INHERITANCE_ARGS+=("-b" "${INPUT_PROBANDS}")
    fi
    bash "${SCRIPT_DIR}"/pipeline_inheritance.sh "${INHERITANCE_ARGS[@]}"
  fi
else
  echo "skipping inheritance matching: Inheritance plugin for VEP was not executed"
  INHERITANCE_OUTPUT="${FILTER_OUTPUT}"
fi
ELAPSED_TIME=$(($SECONDS - $START_TIME))
module purge
echo "step 4/5 inheritance matching completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

# write pipeline version and command headers to output vcf
module load "${MOD_BCF_TOOLS}"
BCFTOOLS_ANNOTATE_HEADER_ARGS=("annotate" "-h" "-")
if [[ "${OUTPUT}" == *.vcf.gz ]]
then
        BCFTOOLS_ANNOTATE_HEADER_ARGS+=("-O" "z")
fi
BCFTOOLS_ANNOTATE_HEADER_ARGS+=("-o" "${OUTPUT}")
BCFTOOLS_ANNOTATE_HEADER_ARGS+=("--no-version" "--threads" "${CPU_CORES}" "${INHERITANCE_OUTPUT}")
printf "##VIP_Version=%s\n##VIP_Command=%s" "${VIP_VERSION}" "${ARGUMENTS}" | bcftools "${BCFTOOLS_ANNOTATE_HEADER_ARGS[@]}"
module purge

echo "step 5/5 generating report ..."
START_TIME=$SECONDS
REPORT_OUTPUT_DIR="${OUTPUT_DIR}"/step5_report/
mkdir -p "${REPORT_OUTPUT_DIR}"
REPORT_OUTPUT="${REPORT_OUTPUT_DIR}/${OUTPUT_FILENAME}.html"
REPORT_ARGS=("-i" "${INHERITANCE_OUTPUT}" "-o" "${REPORT_OUTPUT}")
if [ -n "${INPUT_PROBANDS}" ]; then
	REPORT_ARGS+=("-b" "${INPUT_PROBANDS}")
fi
if [ -n "${INPUT_PED}" ]; then
	REPORT_ARGS+=("-p" "${INPUT_PED}")
fi
if [ -n "${INPUT_PHENO}" ]; then
	REPORT_ARGS+=("-t" "${INPUT_PHENO}")
fi
if [ "${FORCE}" == "1" ]; then
	REPORT_ARGS+=("-f")
fi
if [ -n "${ADDITONAL_ARGS_REPORT}" ]; then
	REPORT_ARGS+=(${ADDITONAL_ARGS_REPORT})
fi
bash "${SCRIPT_DIR}"/pipeline_report.sh "${REPORT_ARGS[@]}"
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 5/5 generating report completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

cp "${REPORT_OUTPUT}" "${OUTPUT_DIR_ABSOLUTE}"/"${OUTPUT_FILENAME}.html"

# done, so we can clean up the entire output dir
if [ "$KEEP" == "0" ]; then
        rm -rf "${OUTPUT_DIR}"
fi

echo "done"
