#!/bin/bash
ANNOTATE_OUTPUT_DIR="${OUTPUT_DIR}"/step1_annotate

VEP_INPUT="${PREPROCESS_OUTPUT}"
VEP_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step1a_vep
VEP_OUTPUT="${VEP_OUTPUT_DIR}"/"${OUTPUT_FILE}"
VEP_OUTPUT_STATS="${VEP_OUTPUT}"

mkdir -p "${VEP_OUTPUT_DIR}"

module load VEP/100.4-foss-2018b-Perl-5.28.0
VEP_ARGS="\
--input_file ${VEP_INPUT} --format vcf \
--output_file ${VEP_OUTPUT} --vcf --compress_output bgzip --force_overwrite \
--stats_file ${VEP_OUTPUT_STATS} --stats_text \
--offline --cache --dir_cache /apps/data/Ensembl/VEP/100 \
--species homo_sapiens --assembly ${ASSEMBLY} \
--flag_pick_allele \
--coding_only \
--no_intergenic \
--af_gnomad --pubmed --gene_phenotype \
--shift_3prime 1 \
--no_escape \
--numbers \
--dont_skip \
--allow_non_variant \
--fork ${CPU_CORES}"

if [ ! -z ${INPUT_REF} ]; then
	VEP_ARGS+=" --fasta ${INPUT_REF} --hgvs"
fi

vep ${VEP_ARGS}

module unload VEP

#CAPICE

CAPICE_INPUT="${INPUT}"
CAPICE_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step1b_capice

if [[ "${OUTPUT_FILE}" == *vcf ]]
then
    CAPICE_OUTPUT="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf/.tsv}"
    CAPICE_OUTPUT_VCF="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf/.vcf.gz}"
else
    CAPICE_OUTPUT="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf.gz/.tsv}"
    CAPICE_OUTPUT_VCF="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE}"
fi

mkdir -p "${CAPICE_OUTPUT_DIR}"

module load CADD/v1.4-foss-2018b
# strip headers from input vcf for cadd
gunzip -c $CAPICE_INPUT | sed '/^#/d' | bgzip > ${CAPICE_OUTPUT_DIR}/input_headerless.vcf.gz
CADD.sh -a -g ${ASSEMBLY} -o ${CAPICE_OUTPUT_DIR}/cadd.tsv.gz ${CAPICE_OUTPUT_DIR}/input_headerless.vcf.gz
module unload CADD

module load CAPICE/v1.3.0-foss-2018b
python ${EBROOTCAPICE}/CAPICE_scripts/model_inference.py \
--input_path ${CAPICE_OUTPUT_DIR}/cadd.tsv.gz \
--model_path ${EBROOTCAPICE}/CAPICE_model/${ASSEMBLY}/xgb_booster.pickle.dat \
--prediction_savepath ${CAPICE_OUTPUT} \

java -Djava.io.tmpdir="${TMPDIR}" -XX:ParallelGCThreads=2 -Xmx1g -jar ${EBROOTCAPICE}/capice2vcf.jar -i ${CAPICE_OUTPUT} -o ${CAPICE_OUTPUT_VCF}
module unload CAPICE

#VcfAnno

VCFANNO_INPUT="${VEP_OUTPUT}"
VCFANNO_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step1c_vcfAnno
VCFANNO_OUTPUT="${VCFANNO_OUTPUT_DIR}"/"${OUTPUT_FILE}"

mkdir -p "${VCFANNO_OUTPUT_DIR}"

module load vcfanno/v0.3.2
module load HTSlib/1.10.2-GCCcore-7.3.0
#inject location of the capice2vcf tool in the vcfAnno config.
CAPICE_OUTPUT_FIXED="${CAPICE_OUTPUT_VCF/\.\//}"
sed "s|OUTPUT_DIR|${CAPICE_OUTPUT_FIXED}|g" conf.template > ${VCFANNO_OUTPUT_DIR}/conf.toml
vcfanno -p ${CPU_CORES} ${VCFANNO_OUTPUT_DIR}/conf.toml ${VCFANNO_INPUT} | bgzip > ${VCFANNO_OUTPUT}
module unload vcfanno
module unload HTSlib

