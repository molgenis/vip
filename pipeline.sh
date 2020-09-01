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

set -euo pipefail

INPUT=""
INPUT_REF=""
INPUT_PED=""
INPUT_PHENO=""
OUTPUT=""
ANN_VEP=""
FORCE=""
KEEP=""
ASSEMBLY=GRCh37
CPU_CORES=4

if [ -z ${TMPDIR+x} ]; then
	TMPDIR=/tmp
fi

usage()
{
  echo "usage: pipeline.sh -i <arg> -o <arg> [-p <arg>] [-f] [-k]

-i,  --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o,  --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-r,  --reference <arg>     optional: Reference sequence FASTA file (.fasta or .fasta.gz).
-p,  --pedigree <arg>      optional: Pedigree file (.ped).
-t,  --phenotypes <arg>    optional: Phenotypes for input samples (see examples).
-f,  --force               optional: Override the output file if it already exists.
-k,  --keep                optional: Keep intermediate files.

--ann_vep                  optional: Variant Effect Predictor (VEP) options

examples:
  pipeline.sh -i in.vcf -o out.vcf
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -p in.ped
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123;HP:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123,sample1/HP:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz --ann_vep "--refseq --exclude_predicted --use_given_ref"
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz -p in.ped -t sample0/HP:0000123;HP:0000234,sample1/HP:0000345 --ann_vep "--refseq --exclude_predicted --use_given_ref" -f -k"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:r:p:t:fk --long input:,output:,reference:,pedigree:,phenotypes:,force,keep,ann_vep: -- "$@")
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
        OUTPUT=$(realpath -s "$2")
        shift 2
        ;;
    -r | --reference)
        INPUT_REF=$(realpath "$2")
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
    --ann_vep)
        ANN_VEP="$2"
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

if [ -z ${INPUT} ]
then
        echo "missing required option -i
	"
	usage
	exit 2
fi
if [ -z ${OUTPUT} ]
then
        echo "missing required option -o
	"
	usage
	exit 2
fi
if [ -z ${FORCE} ]
then
	FORCE=0
fi
if [ -z ${KEEP} ]
then
        KEEP=0
fi

if [ ! -f "${INPUT}" ]
then
	echo "$INPUT does not exist.
	"
	exit 2
fi
if [ -f "${OUTPUT}" ]
then
	if [ "${FORCE}" == "1" ]
	then
		rm "${OUTPUT}"
	else
		echo "${OUTPUT} already exists, use -f to overwrite.
        	"
	        exit 2
	fi
fi
if [ -f "${OUTPUT}".html ]
then
        if [ "${FORCE}" == "1" ]
        then
                rm "${OUTPUT}".html
        else
                echo "${OUTPUT}.html already exists, use -f to overwrite.
                "
                exit 2
        fi
fi
if [ ! -z ${INPUT_PED} ]
then
		if [ ! -f "${INPUT_PED}" ]
		then
			echo "${INPUT_PED} does not exist.
			"
			exit 2
		fi
fi
if [ ! -z ${INPUT_REF} ]
then
                if [ ! -f "${INPUT_REF}" ]
                then
                        echo "${INPUT_REF} does not exist.
                        "
                        exit 2
                fi
fi

OUTPUT_FILE=$(basename "${OUTPUT}")
if [[ "${OUTPUT}" == *.vcf.gz ]]
  then
      OUTPUT_FILENAME=$(basename "${OUTPUT}" .vcf.gz)
  else
      OUTPUT_FILENAME=$(basename "${OUTPUT}" .vcf)
fi
OUTPUT_DIR=$(dirname "${OUTPUT}")/${OUTPUT_FILENAME}_pipeline_out

if [ -d "$OUTPUT_DIR" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm -R "$OUTPUT_DIR"
        else
                echo "$OUTPUT_DIR already exists, use -f to overwrite."
                exit 2
        fi
fi

mkdir -p "${OUTPUT_DIR}"

echo "step 1/4 preprocessing ..."
START_TIME=$SECONDS
source ./pipeline_0_preprocess.sh
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 1/4 preprocessing completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

echo "step 2/4 annotating ..."
START_TIME=$SECONDS
source ./pipeline_1_annotate.sh
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 2/4 annotating completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

echo "step 3/4 filtering ..."
START_TIME=$SECONDS
source ./pipeline_2_filter.sh
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 3/4 filtering completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

mv "${FILTER_OUTPUT}" "${OUTPUT}"
ln -s "${OUTPUT}" "${FILTER_OUTPUT}"

echo "step 4/4 generating report ..."
START_TIME=$SECONDS
source ./pipeline_3_report.sh
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 4/4 generating report completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

cp "${REPORT_OUTPUT}" "${OUTPUT}".html

# done, so we can clean up the entire output dir
if [ "$KEEP" == "0" ]; then
        rm -rf "${OUTPUT_DIR}"
fi

echo "done"
