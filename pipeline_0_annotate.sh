#!/bin/bash
ANNOTATE_OUTPUT_DIR="${OUTPUT_DIR}"/step0_annotate

VEP_INPUT="${INPUT}"
VEP_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step0a_vep
VEP_OUTPUT="${VEP_OUTPUT_DIR}"/"${OUTPUT_FILE}"
VEP_OUTPUT_STATS="${VEP_OUTPUT}"
VEP_OUTPUT_ERRORS="${VEP_OUTPUT}.err"

mkdir -p "${VEP_OUTPUT_DIR}"

module load VEP

vep \
--input_file ${VEP_INPUT} --format vcf \
--output_file ${VEP_OUTPUT} --vcf --compress_output bgzip --force_overwrite \
--warning_file ${VEP_OUTPUT_ERRORS} \
--stats_file ${VEP_OUTPUT_STATS} --stats_text \
--offline --cache --dir_cache /apps/data/Ensembl/VEP/100 --fasta /apps/data/Ensembl/VEP/100/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz \
--species homo_sapiens --assembly ${ASSEMBLY} \
--flag_pick_allele \
--coding_only \
--no_intergenic \
--af_gnomad --pubmed --gene_phenotype \
--hgvs \
--shift_3prime 1 \
--no_escape \
--numbers \
--fork ${CPU_CORES}

module unload VEP

#CAPICE

CAPICE_INPUT="${INPUT}"
CAPICE_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step0b_capice

if [[ "${OUTPUT_FILE}" == *vcf ]]
then
    CAPICE_OUTPUT="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf/.tsv}"
    CAPICE_OUTPUT_VCF="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf/.vcf.gz}"
    CAPICE_OUTPUT_LOG="${CAPICE_OUTPUT}.log"
else
    CAPICE_OUTPUT="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf.gz/.tsv}"
    CAPICE_OUTPUT_VCF="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE}"
    CAPICE_OUTPUT_LOG="${CAPICE_OUTPUT/.tsv/.log}"
fi

mkdir -p "${CAPICE_OUTPUT_DIR}"

module load CADD
# strip headers from input vcf for cadd
gunzip -c $CAPICE_INPUT | sed '/^#/d' | bgzip > ${CAPICE_OUTPUT_DIR}/input_headerless.vcf.gz
CADD.sh -a -g ${ASSEMBLY} -o ${CAPICE_OUTPUT_DIR}/cadd.tsv.gz ${CAPICE_OUTPUT_DIR}/input_headerless.vcf.gz
module unload CADD

module load CAPICE
python ${EBROOTCAPICE}/CAPICE_scripts/model_inference.py \
--input_path ${CAPICE_OUTPUT_DIR}/cadd.tsv.gz \
--model_path ${EBROOTCAPICE}/CAPICE_model/${ASSEMBLY}/xgb_booster.pickle.dat \
--prediction_savepath ${CAPICE_OUTPUT} \
--log_path ${CAPICE_OUTPUT_LOG}

java -Djava.io.tmpdir="${TMPDIR}" -XX:ParallelGCThreads=2 -Xmx1g -jar ${EBROOTCAPICE}/capice2vcf.jar -i ${CAPICE_OUTPUT} -o ${CAPICE_OUTPUT_VCF}
module unload CAPICE

#VcfAnno

VCFANNO_INPUT="${VEP_OUTPUT}"
VCFANNO_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step0c_vcfAnno
VCFANNO_OUTPUT="${VCFANNO_OUTPUT_DIR}"/"${OUTPUT_FILE}"
VCFANNO_OUTPUT_LOG="${VCFANNO_OUTPUT}.log"

mkdir -p "${VCFANNO_OUTPUT_DIR}"

module load vcfanno
module load HTSlib
#inject location of the capice2vcf tool in the vcfAnno config.
CAPICE_OUTPUT_FIXED="${CAPICE_OUTPUT_VCF/\.\//}"
sed "s|OUTPUT_DIR|${CAPICE_OUTPUT_FIXED}|g" conf.template > ${VCFANNO_OUTPUT_DIR}/conf.toml
vcfanno -p ${CPU_CORES} ${VCFANNO_OUTPUT_DIR}/conf.toml ${VCFANNO_INPUT} | bgzip > ${VCFANNO_OUTPUT}
module unload vcfanno
module unload HTSlib

