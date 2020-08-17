#!/bin/bash
set -e

INPUT=""
OUTPUT=""
FORCE=""
DEBUG=""
KEEP=""
LOG_FILE="pipeline.log"

if [ -z ${TMPDIR+x} ]; then
	TMPDIR=/tmp
fi

usage()
{
  echo "usage: pipeline.sh -i <arg> -o <arg> [-f] [-d] [-k]

-i, --input  <arg>        Input VCF file (.vcf or .vcf.gz).
-o, --output <arg>        Output VCF file (.vcf or .vcf.gz).
-f, --force               Override the output file if it already exists.
-d, --debug               Enable debug logging.
-k, --keep                Keep intermediate files."
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:fdk --long input:,output:,force,debug,keep -- "$@")
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
        INPUT="$2"
        shift 2
        ;;
    -o | --output)
        OUTPUT="$2"
        shift 2
        ;;
    -f | --force)
        FORCE=1
        shift
        ;;
    -d | --debug)
        DEBUG=1
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
if [ -z ${DEBUG} ]
then
        DEBUG=0
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

if [ -f "${LOG_FILE}" ]
then
        if [ "${FORCE}" == "1" ]
        then
                rm "${LOG_FILE}"
        else
                echo "${LOG_FILE} already exists, use -f to overwrite.
                "
                exit 2
        fi
fi

OUTPUT_DIR=$(dirname "${OUTPUT}")
mkdir -p "${OUTPUT_DIR}"
OUTPUT_FILE=$(basename "${OUTPUT}")

LOG="${OUTPUT_DIR}"/"${LOG_FILE}"
echo logging to "${LOG}"

if [ "$DEBUG" == "1" ]; then
        exec > >(tee "${LOG}") 2>&1
else
	exec 1>"${LOG}" 2>&1
fi

echo "step 1/3 annotating ..."
START_TIME=$SECONDS
source ./pipeline_0_annotate.sh
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 1/3 annotating completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

echo "step 2/3 filtering ..."
START_TIME=$SECONDS
source ./pipeline_1_filter.sh
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 2/3 filtering completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

if [ "$KEEP" == "0" ]; then
	rm -rf "${VEP_OUTPUT_DIR}"
fi

cp "${GATK_OUTPUT}" "${OUTPUT}"

echo "step 3/3 generating report ..."
START_TIME=$SECONDS
source ./pipeline_2_report.sh
ELAPSED_TIME=$(($SECONDS - $START_TIME))
echo "step 3/3 generating report completed in $(($ELAPSED_TIME/60))m$(($ELAPSED_TIME%60))s"

if [ "$KEEP" == "0" ]; then
        rm -rf "${GATK_OUTPUT_DIR}"
fi

cp "${REPORT_OUTPUT}" "${OUTPUT}".html

if [ "$KEEP" == "0" ]; then
        rm -rf "${REPORT_OUTPUT_DIR}"
fi

echo "done"
