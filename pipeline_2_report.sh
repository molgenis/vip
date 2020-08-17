#!/bin/bash
REPORT_INPUT=${GATK_OUTPUT}
REPORT_OUTPUT_DIR="${OUTPUT_DIR}"/step2_report
REPORT_OUTPUT="${REPORT_OUTPUT_DIR}"/"${OUTPUT_FILE}".html

mkdir -p "${REPORT_OUTPUT_DIR}"

if [ -f "${REPORT_OUTPUT}" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "${REPORT_OUTPUT}"
        else
                echo "${REPORT_OUTPUT} already exists, use -f to overwrite.
                "
                exit 2
        fi
fi

module load vip-report
module load Java

java -jar ${EBROOTVIPMINREPORT}/vcf-report.jar -i ${REPORT_INPUT} -o ${REPORT_OUTPUT}

module unload Java
module unload vip-report
