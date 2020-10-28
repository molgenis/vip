#!/bin/bash
FILTER_INPUT="${VCFANNO_OUTPUT}"
FILTER_OUTPUT_DIR="${OUTPUT_DIR}"/step2_filter
FILTER_OUTPUT="${FILTER_OUTPUT_DIR}"/"${OUTPUT_FILE}"

mkdir -p "${FILTER_OUTPUT_DIR}"

module load BCFtools/1.10.2-GCCcore-7.3.0
module load HTSlib/1.10.2-GCCcore-7.3.0

bcftools filter -e'CAP[*]<0.9' "${FILTER_INPUT}" | \
bgzip -c > "${FILTER_OUTPUT}"

module unload HTSlib
module unload BCFtools
