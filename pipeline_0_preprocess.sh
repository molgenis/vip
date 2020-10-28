#!/bin/bash
PREPROCESS_INPUT="${INPUT}"
PREPROCESS_OUTPUT_DIR="${OUTPUT_DIR}"/step0_preprocess
PREPROCESS_OUTPUT="${PREPROCESS_OUTPUT_DIR}"/"${OUTPUT_FILE}"

mkdir -p "${PREPROCESS_OUTPUT_DIR}"

module load BCFtools/1.10.2-GCCcore-7.3.0

BCFTOOLS_ARGS="\
norm \
-m -both \
-s \
-o ${PREPROCESS_OUTPUT} \
-O z \
--threads ${CPU_CORES}"

if [ ! -z ${INPUT_REF} ]; then
	BCFTOOLS_ARGS+=" -f ${INPUT_REF} -c e"
fi

BCFTOOLS_ARGS+=" ${PREPROCESS_INPUT}"
echo "${BCFTOOLS_ARGS}"
echo 'normalizing ...'
bcftools ${BCFTOOLS_ARGS}
echo 'normalizing done'

module unload BCFtools
