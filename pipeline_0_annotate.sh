#!/bin/bash
VEP_INPUT="${INPUT}"
VEP_OUTPUT_DIR="${OUTPUT_DIR}"/step0_vep
VEP_OUTPUT="${VEP_OUTPUT_DIR}"/"${OUTPUT_FILE}"
VEP_OUTPUT_STATS="${VEP_OUTPUT}"
VEP_OUTPUT_ERRORS="${VEP_OUTPUT}.err"

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
if [ -f "$VEP_OUTPUT_ERRORS" ]
then
        if [ "$FORCE" == "1" ]
        then
                rm "$VEP_OUTPUT_ERRORS"
        else
                echo "$VEP_OUTPUT_ERRORS already exists, use -f to overwrite.
                "
                exit 2
        fi
fi


module load VEP

vep \
--input_file ${VEP_INPUT} --format vcf \
--output_file ${VEP_OUTPUT} --vcf --compress_output bgzip --force_overwrite \
--warning_file ${VEP_OUTPUT_ERRORS} \
--stats_file ${VEP_OUTPUT_STATS} --stats_text \
--offline --cache --dir_cache /apps/data/Ensembl/VEP/100 --fasta /apps/data/Ensembl/VEP/100/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz \
--species homo_sapiens --assembly GRCh37 \
--flag_pick_allele \
--coding_only \
--no_intergenic \
--af_gnomad --pubmed --gene_phenotype \
--hgvs \
--no_escape \
--numbers \
--fork 4

module unload VEP
