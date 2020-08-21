#!/bin/bash
REPORT_INPUT=${FILTER_OUTPUT}
REPORT_OUTPUT_DIR="${OUTPUT_DIR}"/step2_report
REPORT_OUTPUT="${REPORT_OUTPUT_DIR}"/"${OUTPUT_FILE}".html

mkdir -p "${REPORT_OUTPUT_DIR}"

module load vip-report
module load Java

REPORT_ARGS="-i ${REPORT_INPUT} -o ${REPORT_OUTPUT}"
if [ ! -z "${INPUT_PED}" ]; then
	REPORT_ARGS+=" -pd ${INPUT_PED}"
fi
if [ ! -z "${INPUT_PHENO}" ]; then
	REPORT_ARGS+=" -ph ${INPUT_PHENO}"
fi

java -Djava.io.tmpdir="${TMPDIR}" -jar ${EBROOTVIPMINREPORT}/vcf-report.jar ${REPORT_ARGS}

module unload Java
module unload vip-report
