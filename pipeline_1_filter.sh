#!/bin/bash
FILTER_INPUT="${VCFANNO_OUTPUT}"
FILTER_OUTPUT_DIR="${OUTPUT_DIR}"/step1_filter
FILTER_OUTPUT="${FILTER_OUTPUT_DIR}"/"${OUTPUT_FILE}"

mkdir -p "${FILTER_OUTPUT_DIR}"

if [ -f "${FILTER_OUTPUT}" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "${FILTER_OUTPUT}"
        else
                echo "${FILTER_OUTPUT} already exists, use -f to overwrite.
                "
                exit 2
        fi
fi

module load BCFtools
module load HTSlib

bcftools filter -i'CAP[*]>0.9' "${FILTER_INPUT}" | \
bgzip -c > "${FILTER_OUTPUT}"

module unload HTSlib
module unload BCFtools