#!/bin/bash
ANNOTATE_OUTPUT_DIR="${OUTPUT_DIR}"/step0_annotate

VEP_INPUT="${INPUT}"
VEP_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step0a_vep
VEP_OUTPUT="${VEP_OUTPUT_DIR}"/"${OUTPUT_FILE}"
VEP_OUTPUT_STATS="${VEP_OUTPUT}"

mkdir -p "${VEP_OUTPUT_DIR}"

if [ -f "$VEP_OUTPUT" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "$VEP_OUTPUT"
        else
                echo "$VEP_OUTPUT already exists, use -f to overwrite.
                "
                exit 2
        fi
fi
if [ -f "$VEP_OUTPUT_STATS" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "$VEP_OUTPUT_STATS"
        else
                echo "$VEP_OUTPUT_STATS already exists, use -f to overwrite.
                "
                exit 2
        fi
fi

module load VEP

vep \
--input_file ${VEP_INPUT} --format vcf \
--output_file ${VEP_OUTPUT} --vcf --compress_output bgzip --force_overwrite \
--stats_file ${VEP_OUTPUT_STATS} --stats_text \
--offline --cache --dir_cache /apps/data/Ensembl/VEP/100 --fasta /apps/data/Ensembl/VEP/100/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz \
--species homo_sapiens --assembly GRCh37 \
--flag_pick_allele \
--coding_only \
--no_intergenic \
--af_gnomad --pubmed --gene_phenotype \
--hgvs \
--shift_3prime 1 \
--no_escape \
--numbers \
--fork ${PARALLEL_THREADS}

module unload VEP

#CAPICE

CAPICE_INPUT="${INPUT}"
CAPICE_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step0b_capice

if [[ ${OUTPUT_FILE} == *vcf ]]
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

if [ -f "$CAPICE_OUTPUT.vcf.gz" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "$CAPICE_OUTPUT.vcf.gz"
        else
                echo "$CAPICE_OUTPUT.vcf.gz already exists, use -f to overwrite.
                "
                exit 2
        fi
fi

if [ -f "$CAPICE_OUTPUT_LOG" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "$CAPICE_OUTPUT_LOG"
        else
                echo "$CAPICE_OUTPUT_LOG already exists, use -f to overwrite.
                "
                exit 2
        fi
fi

module load CADD
# strip headers from input vcf for cadd
gunzip -c $CAPICE_INPUT | sed '/^#/d' | bgzip > ${CAPICE_OUTPUT_DIR}/input_headerless.vcf.gz
CADD.sh -a -g ${ASSEMBLY} -o ${CAPICE_OUTPUT_DIR}/cadd.tsv.gz ${CAPICE_OUTPUT_DIR}/input_headerless.vcf.gz
module unload CADD

module load CAPICE
python ${EBROOTCAPICE}/CAPICE_scripts/model_inference.py \
--input_path ${CAPICE_OUTPUT_DIR}/cadd.tsv.gz \
--model_path ${EBROOTCAPICE}/CAPICE_model/xgb_booster.pickle.dat \
--prediction_savepath ${CAPICE_OUTPUT} \
--log_path ${CAPICE_OUTPUT_LOG}

module load Java
java -Djava.io.tmpdir="${TMPDIR}" -XX:ParallelGCThreads=2 -Xmx1g -jar capice2vcf.jar -i ${CAPICE_OUTPUT} -o ${CAPICE_OUTPUT_VCF}
module unload Java

#VcfAnno

VCFANNO_INPUT="${VEP_OUTPUT}"
VCFANNO_OUTPUT_DIR="${ANNOTATE_OUTPUT_DIR}"/step0c_vcfAnno
VCFANNO_OUTPUT="${VCFANNO_OUTPUT_DIR}"/"${OUTPUT_FILE}"
VCFANNO_OUTPUT_LOG="${VCFANNO_OUTPUT}.log"

mkdir -p "${VCFANNO_OUTPUT_DIR}"

if [ -f "$VCFANNO_OUTPUT" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "$VCFANNO_OUTPUT"
        else
                echo "$VCFANNO_OUTPUT already exists, use -f to overwrite.
                "
                exit 2
        fi
fi

module load vcfanno
module load HTSlib
#inject location of the capice2vcf tool in the vcfAnno config.
CAPICE_OUTPUT_fixed="${CAPICE_OUTPUT_VCF/\.\//}"
sed "s|OUTPUT_DIR|${CAPICE_OUTPUT_fixed}|g" conf.template > ${VCFANNO_OUTPUT_DIR}/conf.toml
vcfanno -p ${PARALLEL_THREADS} ${VCFANNO_OUTPUT_DIR}/conf.toml ${VCFANNO_INPUT} | bgzip > ${VCFANNO_OUTPUT}
module unload vcfanno
module unload HTSlib

