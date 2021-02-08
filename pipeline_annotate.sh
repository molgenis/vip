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

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [ -n "$SLURM_JOB_ID" ]; then SCRIPT_DIR=$(dirname $(scontrol show job "$SLURM_JOBID" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)); else SCRIPT_DIR=$(dirname $(realpath "$0")); fi

# shellcheck source=utils/header.sh
source "${SCRIPT_DIR}"/utils/header.sh

INPUT=""
OUTPUT=""
INPUT_REF=""
INPUT_PHENO=""
ASSEMBLY=GRCh37
ANN_VEP=""
CPU_CORES=4
FORCE=0
KEEP=0

usage()
{
  echo "usage: pipeline_annotate.sh -i <arg> -o <arg> [-r <arg>] [-c <arg>] [-a <arg>] [-f] [-k]

-i,  --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o,  --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-r,  --reference <arg>     optional: Reference sequence FASTA file (.fasta or .fasta.gz).
-a,  --assembly            optional: Assembly to be used (e.g. GRCh37). Default: GRCh37
-t,  --phenotypes <arg>    optional: Phenotypes for input samples (see examples).
-c,  --cpu_cores           optional: Number of CPU cores available for this process. Default: 4
-f,  --force               optional: Override the output file if it already exists.
-k,  --keep                optional: Keep intermediate files.

--ann_vep                  optional: Variant Effect Predictor (VEP) options

examples:
  pipeline_annotate.sh -i in.vcf -o out.vcf
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -a GRCh37
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123;HP:0000234
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123,sample1/HP:0000234
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz --ann_vep \"--refseq --exclude_predicted --use_given_ref\"
  pipeline_annotate.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz -a GRCh37 -t sample0/HP:0000123;HP:0000234,sample1/HP:0000345 --ann_vep \"--refseq --exclude_predicted --use_given_ref\" -c 2 -f -k"
}

get_unique_phenotypes() {
  IFS=',' read -ra SAMPLE_PHENOTYPES <<< "$1"
  for i in "${SAMPLE_PHENOTYPES[@]}"
  do
    if [[ "$i" =~ (.*\/)?(.*) ]]
    then
      IFS=';' read -ra PHENOTYPES <<< "${BASH_REMATCH[2]}"
      for j in "${PHENOTYPES[@]}"
      do
        UNIQUE_PHENOTYPES["$j"]=1
      done
    else
      echo -e "Invalid phenotype '${INPUT_PHENO}' in -t or --phenotypes\n"
      usage
      exit 2
    fi
  done
}

PARSED_ARGUMENTS=$(getopt -a -n pipeline -o i:o:r:a:t:c:fk --long input:,output:,reference:,assembly:,phenotypes:,cpu_cores:,force,keep,ann_vep: -- "$@")
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
    -t | --phenotypes)
      INPUT_PHENO="$2"
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

if [ -z "${INPUT}" ]
then
  echo -e "missing required option -i\n"
	usage
	exit 2
fi
if [ -z "${OUTPUT}" ]
then
  echo -e "missing required option -o\n"
	usage
	exit 2
fi

if [ ! -f "${INPUT}" ]
then
	echo -e "$INPUT does not exist.\n"
	exit 2
fi
if [ -f "${OUTPUT}" ]
then
	if [ "${FORCE}" == "1" ]
	then
		rm "${OUTPUT}"
	else
		echo -e "${OUTPUT} already exists, use -f to overwrite.\n"
    exit 2
	fi
fi
if [ ! -z "${INPUT_REF}" ]
then
  if [ ! -f "${INPUT_REF}" ]
  then
    echo -e "${INPUT_REF} does not exist.\n"
    exit 2
  fi
fi


if [ -z "${TMPDIR+x}" ]; then
	TMPDIR=/tmp
fi

#VcfAnno
VCFANNO_INPUT="${INPUT}"
VCFANNO_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step1_vcfAnno
VCFANNO_OUTPUT="${VCFANNO_OUTPUT_DIR}"/vcfanno_pre.vcf.gz
VCFANNO_PRE_CONF="${VCFANNO_OUTPUT_DIR}"/conf_pre.toml

rm -rf "${VCFANNO_OUTPUT_DIR}"
mkdir -p "${VCFANNO_OUTPUT_DIR}"

cat > "${VCFANNO_PRE_CONF}" << EOT
[[annotation]]
file="/apps/data/VKGL/vkgl_consensus_jan2021_normalized.vcf.gz"
fields = ["VKGL_CL", "AMC", "EMC", "LUMC", "NKI", "RMMC", "UMCG", "UMCU", "VUMC"]
ops=["self","self","self","self","self","self","self","self","self"]
names=["VKGL", "VKGL_AMC", "VKGL_EMC", "VKGL_LUMC", "VKGL_NKI", "VKGL_RMMC", "VKGL_UMCG", "VKGL_UMCU", "VKGL_VUMC"]

[[annotation]]
file="/apps/data/CAPICE/${ASSEMBLY}/capice_v1.0_indels.vcf.gz"
fields = ["CAP"]
ops=["self"]
names=["CAP"]

[[annotation]]
file="/apps/data/CAPICE/${ASSEMBLY}/capice_v1.0_snvs.vcf.gz"
fields = ["CAP"]
ops=["self"]
names=["CAP"]

[[annotation]]
file="/apps/data/UMCG/MVL/${ASSEMBLY}/Artefact_Totaal-Molecular_variants-2020-10-08_07-49-09_normalized.vcf.gz"
fields = ["MVL"]
ops=["self"]
names=["MVLA"]
EOT

module load "${MOD_VCF_ANNO}"
module load "${MOD_HTS_LIB}"

VCFANNO_ARGS=("-p" "${CPU_CORES}" "${VCFANNO_PRE_CONF}" "${VCFANNO_INPUT}")
vcfanno "${VCFANNO_ARGS[@]}" | bgzip > "${VCFANNO_OUTPUT}"

module purge

# CAPICE
CAPICE_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step2_capice
BCFTOOLS_FILTER_INPUT="${VCFANNO_OUTPUT}"
BCFTOOLS_FILTER_OUTPUT="${CAPICE_OUTPUT_DIR}"/vcfanno_bcftools_filter.vcf.gz
CAPICE_INPUT="${BCFTOOLS_FILTER_OUTPUT}"
VCFANNO_POST_CONF="${CAPICE_OUTPUT_DIR}"/conf_post.toml

if [[ "${OUTPUT_FILE}" == *vcf ]]
then
  CAPICE_OUTPUT="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf/.tsv}"
else
  CAPICE_OUTPUT="${CAPICE_OUTPUT_DIR}"/"${OUTPUT_FILE/.vcf.gz/.tsv}"
fi
CAPICE_OUTPUT_VCF="${CAPICE_OUTPUT_DIR}"/vcfanno_bcftools_filter_capice.vcf.gz

rm -rf "${CAPICE_OUTPUT_DIR}"
mkdir -p "${CAPICE_OUTPUT_DIR}"

module load "${MOD_BCF_TOOLS}"
bcftools filter -i 'CAP="."' --threads "${CPU_CORES}" "${BCFTOOLS_FILTER_INPUT}" | bgzip -c > "${BCFTOOLS_FILTER_OUTPUT}"
module purge

if [[ "${ASSEMBLY}" == GRCh37 ]]
then
  if [ `zgrep -c -m 1 "^[^#]" "${BCFTOOLS_FILTER_OUTPUT}"` -eq 0 ]
  then
    VCFANNO_ALL_OUTPUT="${BCFTOOLS_FILTER_INPUT}"
    echo "skipping CAPICE score calculation because all variants have precomputed scores ..."
  else
    VCFANNO_ALL_OUTPUT="${CAPICE_OUTPUT_DIR}"/vcfanno_all.vcf.gz
    echo "calculating CAPICE scores for variants without precomputed score ..."

    module load "${MOD_CADD}"
    # strip headers from input vcf for cadd
    CADD_INPUT="${CAPICE_OUTPUT_DIR}/input_headerless_$(date +%s).vcf.gz"
    gunzip -c "$CAPICE_INPUT" | sed '/^#/d' | bgzip > "${CADD_INPUT}"
    CADD_ARGS=("-a" "-g" "${ASSEMBLY}" "-o" "${CAPICE_OUTPUT_DIR}/cadd.tsv.gz" "-c" "${CPU_CORES}" "-s" "${CADD_INPUT}")
    CADD.sh "${CADD_ARGS[@]}"
    module purge

    module load "${MOD_CAPICE}"
    PYTHON_ARGS=("${EBROOTCAPICE}/CAPICE_scripts/model_inference.py" "--input_path" "${CAPICE_OUTPUT_DIR}/cadd.tsv.gz" "--model_path" "${EBROOTCAPICE}/CAPICE_model/${ASSEMBLY}/xgb_booster.pickle.dat" "--prediction_savepath" "${CAPICE_OUTPUT}")
    python "${PYTHON_ARGS[@]}"

    CAPICE_ARGS=("-Djava.io.tmpdir=${TMPDIR}" "-XX:ParallelGCThreads=2" "-Xmx1g" "-jar" "${EBROOTCAPICE}/capice2vcf.jar" "-i" "${CAPICE_OUTPUT}" "-o" "${CAPICE_OUTPUT_VCF}")

    if [ "${FORCE}" == "1" ]
    then
      CAPICE_ARGS+=("-f")
    fi
    java "${CAPICE_ARGS[@]}"

    module purge

	  cat > "${VCFANNO_POST_CONF}" << EOT
[[annotation]]
file="${CAPICE_OUTPUT_VCF}"
fields = ["CAP"]
ops=["self"]
names=["CAP"]
EOT

    module load "${MOD_VCF_ANNO}"
    module load "${MOD_HTS_LIB}"

    VCFANNO_ARGS=("-p" "${CPU_CORES}" "${VCFANNO_POST_CONF}" "${VCFANNO_OUTPUT}")
    vcfanno "${VCFANNO_ARGS[@]}" | bgzip > "${VCFANNO_ALL_OUTPUT}"

    module purge
  fi
else
  echo "Skipping capice for ${ASSEMBLY}"
  VCFANNO_ALL_OUTPUT="${VCFANNO_OUTPUT}"
fi

# VEP
VEP_INPUT="${VCFANNO_ALL_OUTPUT}"
VEP_OUTPUT_DIR="${OUTPUT_DIR_ABSOLUTE}"/step3_vep
VEP_OUTPUT="${VEP_OUTPUT_DIR}"/"${OUTPUT_FILE}"
VEP_OUTPUT_STATS="${VEP_OUTPUT}"
rm -rf "${VEP_OUTPUT_DIR}"
mkdir -p "${VEP_OUTPUT_DIR}"

if [ -n "${INPUT_PHENO}" ]
then
  module load "${MOD_VIBE}"

  declare -A UNIQUE_PHENOTYPES
  get_unique_phenotypes "${INPUT_PHENO}"
  for i in "${!UNIQUE_PHENOTYPES[@]}"
  do
    VIBE_OUTPUT="${VEP_OUTPUT_DIR}/${i//[:]/_}.txt"
    VIBE_ARGS=("-t" "/apps/data/VIBE/vibe-5.0.0-hdt/vibe-5.0.0.hdt" "-w" "/apps/data/VIBE/hp_2020-12-07.owl")
    VIBE_ARGS+=("-p" "$i")
    VIBE_ARGS+=("-l" "-o" "${VIBE_OUTPUT}")
    java -Djava.io.tmpdir="${TMPDIR}" -XX:ParallelGCThreads=2 -jar "${EBROOTVIBE}"/vibe.jar "${VIBE_ARGS[@]}"

    echo -e "#HPO=$i\n$(cat "${VIBE_OUTPUT}")" > "${VIBE_OUTPUT}"
  done

  module purge
fi

module load "${MOD_VEP}"
VEP_ARGS=("--input_file" "${VEP_INPUT}" "--format" "vcf")
VEP_ARGS+=("--output_file" "${VEP_OUTPUT}" "--vcf")
if [[ "${OUTPUT}" == *.vcf.gz ]]
then
	VEP_ARGS+=("--compress_output" "bgzip")
fi

VEP_ARGS+=("--stats_file" "${VEP_OUTPUT_STATS}" "--stats_text")
VEP_ARGS+=("--offline" "--cache" "--dir_cache" "/apps/data/Ensembl/VEP/100")
VEP_ARGS+=("--species" "homo_sapiens" "--assembly" "${ASSEMBLY}")
VEP_ARGS+=("--symbol")
VEP_ARGS+=("--flag_pick_allele")
VEP_ARGS+=("--no_intergenic")
VEP_ARGS+=("--af_gnomad" "--pubmed")
VEP_ARGS+=("--shift_3prime" "1")
VEP_ARGS+=("--allele_number")
VEP_ARGS+=("--numbers")
VEP_ARGS+=("--dont_skip")
VEP_ARGS+=("--allow_non_variant")
VEP_ARGS+=("--fork" "${CPU_CORES}")

if [ -n "${INPUT_REF}" ]; then
	VEP_ARGS+=("--fasta" "${INPUT_REF}" "--hgvs")
fi

if [ -n "${ANN_VEP}" ]; then
	# shellcheck disable=SC2206
	VEP_ARGS+=(${ANN_VEP})
fi

vep "${VEP_ARGS[@]}"

module purge

mv "${VEP_OUTPUT}" "${OUTPUT}"
ln -s "${OUTPUT}" "${VEP_OUTPUT}"

if [ "$KEEP" == "0" ]; then
  rm -rf "${VEP_OUTPUT_DIR}"
  rm -rf "${CAPICE_OUTPUT_DIR}"
  rm -rf "${VCFANNO_OUTPUT_DIR}"
fi