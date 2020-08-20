#!/bin/bash
GATK_INPUT="${VCFANNO_OUTPUT}"
GATK_INPUT_INDEX="${GATK_INPUT}".tbi
GATK_OUTPUT_DIR="${OUTPUT_DIR}"/step1_filter
GATK_OUTPUT="${GATK_OUTPUT_DIR}"/"${OUTPUT_FILE}"

mkdir -p "${GATK_OUTPUT_DIR}"

if [ -f "${GATK_INPUT_INDEX}" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "${GATK_INPUT_INDEX}"
        else
                echo "${GATK_INPUT_INDEX} already exists, use -f to overwrite.
                "
                exit 2
        fi
fi
if [ -f "${GATK_OUTPUT}" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "${GATK_OUTPUT}"
        else
                echo "${GATK_OUTPUT} already exists, use -f to overwrite.
                "
                exit 2
        fi
fi

module load HTSlib
tabix "${GATK_INPUT}"
module unload HTSlib

module load GATK
gatk VariantFiltration \
   -V "${GATK_INPUT}" \
   -O "${GATK_OUTPUT}" \
   --filter-expression "CAP > 0.9" \
   --filter-name "CAP"
module unload GATK
