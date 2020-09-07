#!/bin/bash
#SBATCH --job-name=vip_annotate
#SBATCH --output=vip_annotate.out
#SBATCH --error=vip_annotate.err
#SBATCH --time=05:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16gb
#SBATCH --nodes=1
#SBATCH --export=NONE
#SBATCH --get-user-env=L60

source utils/header.sh

INPUT=""
OUTPUT=""
INPUT_REF=""
ASSEMBLY=""
ANN_VEP=""
CPU_CORES=""
FORCE=""
KEEP=""

usage()
{
  echo "usage: pipeline_annotate.sh -i <arg> -o <arg> [-r <arg>] [-c <arg>] [-a <arg>] [-f] [-k]

-i,  --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o,  --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-r,  --reference <arg>     optional: Reference sequence FASTA file (.fasta or .fasta.gz).
-a,  --assembly            optional: Assembly to be used (e.g. GRCh37). Default: GRCh37
-c,  --cpu_cores           optional: Number of CPU cores available for this process. Default: 4
-f,  --force               optional: Override the output file if it already exists.
-k,  --keep                optional: Keep intermediate files.

--ann_vep                  optional: Variant Effect Predictor (VEP) options

examples:
  pipeline_annotate.sh -i in.vcf -o out.vcf
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -a GRCh37
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz --ann_vep "\""--refseq --exclude_predicted --use_given_ref"\""
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz -a GRCh37 --ann_vep "\""--refseq --exclude_predicted --use_given_ref"\"" -c 2 -f -k"
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:r:a:c:fk --long input:,output:,reference:,assembly:,cpu_cores:,force,keep,ann_vep: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
	usage
	exit 2
fi

eval set -- "$PARSED_ARGUMENTS"
while :
do
  case "$1" in
    -i | --input)
        INPUT=$(realpath "$2")
        shift 2
        ;;
    -o | --output)
        OUTPUT_ARG="$2"
        OUTPUT_DIR_RELATIVE=$(dirname "$OUTPUT_ARG")
        OUTPUT_DIR_ABSOLUTE=$(realpath "$OUTPUT_DIR_RELATIVE")
        OUTPUT_FILE=$(basename "$OUTPUT_ARG")
        OUTPUT="${OUTPUT_DIR_ABSOLUTE}"/"${OUTPUT_FILE}"
        shift 2
        ;;
    -r | --reference)
        INPUT_REF=$(realpath "$2")
        shift 2
        ;;
    -c | --cpu_cores)
        CPU_CORES="$2"
        shift 2
        ;;
    -a | --assembly)
        ASSEMBLY="$2"
        shift 2
        ;;
    --ann_vep)
        ANN_VEP="$2"
        shift 2
        ;;
    -f | --force)
        FORCE=1
        shift
        ;;
    -k | --keep)
        KEEP=1
        shift
        ;;
    --)
        shift
        break
        ;;
    *)
        usage
	exit 2
        ;;
  esac
done

if [ -z ${INPUT} ]
then
        echo "missing required option -i
	"
	usage
	exit 2
fi
if [ -z ${OUTPUT} ]
then
        echo "missing required option -o
	"
	usage
	exit 2
fi
if [ -z ${ASSEMBLY} ]
then
	ASSEMBLY=GRCh37
fi
if [ -z ${CPU_CORES} ]
then
	CPU_CORES=4
fi
if [ -z ${FORCE} ]
then
	FORCE=0
fi
if [ -z ${KEEP} ]
then
        KEEP=0
fi

if [ ! -f "${INPUT}" ]
then
	echo "$INPUT does not exist.
	"
	exit 2
fi
if [ -f "${OUTPUT}" ]
then
	if [ "${FORCE}" == "1" ]
	then
		rm "${OUTPUT}"
	else
		echo "${OUTPUT} already exists, use -f to overwrite.
        	"
	        exit 2
	fi
fi
if [ ! -z "${INPUT_REF}" ]
then
                if [ ! -f "${INPUT_REF}" ]
                then
                        echo "${INPUT_REF} does not exist.
                        "
                        exit 2
                fi
fi


if [ -z ${TMPDIR+x} ]; then
	TMPDIR=/tmp
fi

VEP_INPUT="${INPUT}"
VEP_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step1_vep
VEP_OUTPUT="${VEP_OUTPUT_DIR}"/"${OUTPUT_FILE}"
VEP_OUTPUT_STATS="${VEP_OUTPUT}"
rm -rf "${VEP_OUTPUT_DIR}"
mkdir -p "${VEP_OUTPUT_DIR}"

module load VEP
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

if [ ! -z "${ANN_VEP}" ]; then
	VEP_ARGS+=" ${ANN_VEP}"
fi

vep ${VEP_ARGS}

module purge

#CAPICE

CAPICE_INPUT="${INPUT}"
CAPICE_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step2_capice

if [[ "${OUTPUT_FILE}" == *vcf ]]
then
    CAPICE_OUTPUT="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf/.tsv}"
    CAPICE_OUTPUT_VCF="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf/.vcf.gz}"
else
    CAPICE_OUTPUT="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf.gz/.tsv}"
    CAPICE_OUTPUT_VCF="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE}"
fi

rm -rf "${CAPICE_OUTPUT_DIR}"
mkdir -p "${CAPICE_OUTPUT_DIR}"

module load CADD
# strip headers from input vcf for cadd
CADD_INPUT="${CAPICE_OUTPUT_DIR}/input_headerless_$(date +%s).vcf.gz"
gunzip -c $CAPICE_INPUT | sed '/^#/d' | bgzip > ${CADD_INPUT}
CADD.sh -a -g ${ASSEMBLY} -o ${CAPICE_OUTPUT_DIR}/cadd.tsv.gz ${CADD_INPUT}
module purge

module load CAPICE
python ${EBROOTCAPICE}/CAPICE_scripts/model_inference.py \
--input_path ${CAPICE_OUTPUT_DIR}/cadd.tsv.gz \
--model_path ${EBROOTCAPICE}/CAPICE_model/${ASSEMBLY}/xgb_booster.pickle.dat \
--prediction_savepath ${CAPICE_OUTPUT} \

CAPICE_ARGS="\
-Djava.io.tmpdir="${TMPDIR}" \
-XX:ParallelGCThreads=2 \
-Xmx1g \
-jar ${EBROOTCAPICE}/capice2vcf.jar \
-i ${CAPICE_OUTPUT} \
-o ${CAPICE_OUTPUT_VCF}
"
if [ "${FORCE}" == "1" ]
then
	CAPICE_ARGS+=" -f"
fi
java ${CAPICE_ARGS}

module purge

#VcfAnno

VCFANNO_INPUT="${VEP_OUTPUT}"
VCFANNO_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step3_vcfAnno
VCFANNO_OUTPUT="${VCFANNO_OUTPUT_DIR}"/"${OUTPUT_FILE}"

rm -rf "${VCFANNO_OUTPUT_DIR}"
mkdir -p "${VCFANNO_OUTPUT_DIR}"

module load vcfanno
module load HTSlib
#inject location of the capice2vcf tool in the vcfAnno config.
CAPICE_OUTPUT_FIXED="${CAPICE_OUTPUT_VCF/\.\//}"
sed "s|OUTPUT_DIR|${CAPICE_OUTPUT_FIXED}|g" conf.template > ${VCFANNO_OUTPUT_DIR}/conf.toml

VCFANNO_ARGS="-p ${CPU_CORES} ${VCFANNO_OUTPUT_DIR}/conf.toml ${VCFANNO_INPUT}"
if [[ "${OUTPUT}" == *.vcf.gz ]]
then
	vcfanno ${VCFANNO_ARGS} | bgzip > ${VCFANNO_OUTPUT}
else
	vcfanno ${VCFANNO_ARGS} > ${VCFANNO_OUTPUT}
fi

module purge

mv "${VCFANNO_OUTPUT}" "${OUTPUT}"
ln -s "${OUTPUT}" "${VCFANNO_OUTPUT}"

if [ "$KEEP" == "0" ]; then
        rm -rf "${VEP_OUTPUT_DIR}"
        rm -rf "${CAPICE_OUTPUT_DIR}"
        rm -rf "${VCFANNO_OUTPUT_DIR}"
fi
