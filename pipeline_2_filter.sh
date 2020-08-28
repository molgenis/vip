#!/bin/bash
FILTER_INPUT="${VCFANNO_OUTPUT}"
FILTER_OUTPUT_DIR="${OUTPUT_DIR}"/step2_filter
FILTER_OUTPUT="${FILTER_OUTPUT_DIR}"/"${OUTPUT_FILE}"

mkdir -p "${FILTER_OUTPUT_DIR}"

module load BCFtools
module load HTSlib

bcftools filter -e'CAP[*]<0.9' "${FILTER_INPUT}" | \
bgzip -c > "${FILTER_OUTPUT}"

module unload HTSlib
module unload BCFtools
