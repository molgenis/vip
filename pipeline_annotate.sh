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
#SBATCH --tmp=4gb

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

# shellcheck source=utils/header.sh
source "${SCRIPT_DIR}"/utils/header.sh
# shellcheck source=utils/utils.sh
source "${SCRIPT_DIR}"/utils/utils.sh

usage() {
  echo -e "usage: ${SCRIPT_NAME} -i <arg>

-i, --input      <arg>    required: Input VCF file (.vcf or .vcf.gz).
-o, --output     <arg>    optional: Output VCF file (.vcf.gz).
-t, --phenotypes <arg>    optional: Phenotypes for input samples.

-c, --config     <arg>    optional: Comma separated list of configuration files (.cfg)
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.
-h, --help                optional: Print this message and exit.

config:
  annotate_phenotype_matching             Phenotype matching algorithm (hpo or vibe, default: hpo)
  annotate_vep_dir_cache                  VEP: Cache directory.
  annotate_vep_coding_only                VEP: Only return consequences that fall in the coding regions of transcripts (0 or 1, default: 0).
  annotate_vep_no_intergenic              VEP: Do not include intergenic consequences in the output (0 or 1, default: 1).
  annotate_vep_plugin_Hpo                 VEP: Path to genes_to_phenotype.tsv (default ./resources/hpo_YYYYmmdd.tsv)
  annotate_vep_plugin_Inheritance         VEP: Path to gene_inheritance_modes.tsv
  annotate_vep_plugin_PreferredTranscript VEP: Path to preferred transcript file for the PreferredTranscript plugin.
  annotate_vep_plugin_SpliceAI            VEP: Comma-separated paths to SpliceAI snv and indel files.
  annotate_vep_plugin_VKGL                VEP: Path to VKGL consensus file.
  annotate_vep_plugin_VKGL_mode           VEP: VKGL plugin mode: 0=all, 1=consensus only.
  annotate_vep_plugin_Artefact            VEP: Path to artefacts file.
  annotate_vep                            Variant Effect Predictor (VEP) options.
  assembly                                see 'bash pipeline.sh --help' for usage.
  reference                               see 'bash pipeline.sh --help' for usage.
  cpu_cores                               see 'bash pipeline.sh --help' for usage.
  singularity_image_dir                   see 'bash pipeline.sh --help' for usage."
}

get_unique_phenotypes() {
  IFS=',' read -ra SAMPLE_PHENOTYPES <<<"$1"
  for i in "${SAMPLE_PHENOTYPES[@]}"; do
    if [[ "$i" =~ (.*\/)?(.*) ]]; then
      IFS=';' read -ra PHENOTYPES <<<"${BASH_REMATCH[2]}"
      for j in "${PHENOTYPES[@]}"; do
        UNIQUE_PHENOTYPES["$j"]=1
      done
    else
      echo -e "Invalid phenotype '${phenotypes}' in -t or --phenotypes\n"
      usage
      exit 2
    fi
  done
}

# arguments:
#   $1 vepDirCache
#   $2 vepCodingOnly
#   $3 vepNoIntergenic
#   $4 vepHpoGenPhenoFilePath
#   $5 vepPluginInheritanceFilePath
#   $6 vepPluginPreferredTranscriptFilePath
#   $7 vepPluginSpliceAiFilePaths
#   $8 vepPluginVKGLFilePath
#   $9 vepPluginArtefactFilePath
validateVep() {
  local -r vepDirCache="${1}"
  local -r vepCodingOnly="${2}"
  local -r vepNoIntergenic="${3}"
  local -r vepHpoGenPhenoFilePath="${4}"
  local -r vepPluginInheritanceFilePath="${5}"
  local -r vepPluginPreferredTranscriptFilePath="${6}"
  local -r vepPluginSpliceAiFilePaths="${7}"
  local -r vepPluginVKGLFilePath="${8}"
  local -r vepPluginArtefactFilePath="${9}"

  if [[ -z "${vepDirCache}" ]]; then
    echo -e "missing required annotate_vep_dir_cache config value."
    exit 1
  fi
  if [[ ! -d "${vepDirCache}" ]]; then
    echo -e "annotate_vep_dir_cache ${vepDirCache} does not exist."
    exit 1
  fi

  if [[ -z "${vepCodingOnly}" ]]; then
    echo -e "missing required annotate_vep_coding_only config value."
    exit 1
  fi
  if [[ "${vepCodingOnly}" != "0" ]] && [[ "${vepCodingOnly}" != "1" ]]; then
    echo -e "annotate_vep_coding_only ${vepCodingOnly} invalid (valid values: 0 or 1)."
    exit 1
  fi

  if [[ -z "${vepNoIntergenic}" ]]; then
    echo -e "missing required annotate_vep_no_intergenic config value."
    exit 1
  fi
  if [[ "${vepNoIntergenic}" != "0" ]] && [[ "${vepNoIntergenic}" != "1" ]]; then
    echo -e "annotate_vep_no_intergenic ${vepNoIntergenic} invalid (valid values: 0 or 1)."
    exit 1
  fi

  if [[ -z "${vepHpoGenPhenoFilePath}" ]]; then
    echo -e "missing required annotate_vep_plugin_Hpo config value."
    exit 1
  fi
  if [[ ! -f "${vepHpoGenPhenoFilePath}" ]]; then
    echo -e "annotate_vep_plugin_Hpo ${vepHpoGenPhenoFilePath} does not exist."
    exit 1
  fi

  if [[ -n "${vepPluginInheritanceFilePath}" ]] && [[ ! -f "${vepPluginInheritanceFilePath}" ]]; then
    echo -e "annotate_vep_plugin_Inheritance ${vepPluginInheritanceFilePath} does not exist."
    exit 1
  fi
  if [[ -n "${vepPluginPreferredTranscriptFilePath}" ]] && [[ ! -f "${vepPluginPreferredTranscriptFilePath}" ]]; then
    echo -e "annotate_vep_plugin_PreferredTranscript ${vepPluginPreferredTranscriptFilePath} does not exist."
    exit 1
  fi

  if [[ -n "${vepPluginSpliceAiFilePaths}" ]]; then
    local spliceAiFilePathsArr
    IFS=',' read -ra spliceAiFilePathsArr <<<"${vepPluginSpliceAiFilePaths}"
    if [[ "${#spliceAiFilePathsArr[@]}" != "2" ]]; then
      echo -e "annotate_vep_plugin_SpliceAI contains ${#spliceAiFilePathsArr[@]} paths instead of two."
      exit 1
    fi
    for i in "${spliceAiFilePathsArr[@]}"; do
      if [[ ! -f "${i}" ]]; then
        echo -e "annotate_vep_plugin_SpliceAI ${i} does not exist."
        exit 1
      fi
    done
  fi

  if [[ -n "${vepPluginVKGLFilePath}" ]] && [[ ! -f "${vepPluginVKGLFilePath}" ]]; then
    echo -e "annotate_vep_plugin_VKGL ${vepPluginVKGLFilePath} does not exist."
    exit 1
  fi

  if [[ -n "${vepPluginArtefactFilePath}" ]] && [[ ! -f "${vepPluginArtefactFilePath}" ]]; then
    echo -e "annotate_vep_plugin_VKGL ${vepPluginArtefactFilePath} does not exist."
    exit 1
  fi
}

# arguments:
#   $1 vibeHdtPath
#   $2 vibeHpoPath
validateVibe() {
  local -r vibeHdtPath="${1}"
  local -r vibeHpoPath="${2}"

  if [[ ! -f "${vibeHdtPath}" ]]; then
    echo -e "VIBE hdt ${vibeHdtPath} does not exist."
    exit 1
  fi
  if [[ ! -f "${vibeHpoPath}" ]]; then
    echo -e "VIBE hpo ${vibeHpoPath} does not exist."
    exit 1
  fi
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 phenotypes (optional)
#   $4 force
#   $5 path to reference sequence (optional)
#   $6 phenotype matching
#   $7 cpu cores
validate() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r phenotypes="${3}"
  local -r force="${4}"
  local -r referencePath="${5}"
  local -r phenotypeMatching="${6}"
  local -r processes="${7}"

  if ! validateInputPath "${inputFilePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  if ! validateOutputPath "${outputFilePath}" "${force}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  #TODO validate phenotypes

  if ! validateReferencePath "${referencePath}"; then
    echo -e "Try '${SCRIPT_NAME} --help' for more information."
    exit 1
  fi

  #TODO validate cpu cores

  if [[ -z "${phenotypeMatching}" ]]; then
    echo -e "missing required annotate_phenotype_matching config value."
    exit 1
  fi
  if [[ "${phenotypeMatching}" != "hpo" ]] && [[ "${phenotypeMatching}" != "vibe" ]]; then
    echo -e "annotate_phenotype_matching ${phenotypeMatching} invalid (valid values: hpo or vibe)."
    exit 1
  fi
}

# arguments:
#   $1 path to output file
createVcfannoConfig() {
  local -r outputFilePath="${1}"

  cat >"${outputFilePath}" <<EOT

[[annotation]]
file="/apps/data/CAPICE/${assembly}/capice_v1.0_indels.vcf.gz"
fields = ["CAP"]
ops=["self"]
names=["CAP"]

[[annotation]]
file="/apps/data/CAPICE/${assembly}/capice_v1.0_snvs.vcf.gz"
fields = ["CAP"]
ops=["self"]
names=["CAP"]

EOT
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 processes
executeVcfanno() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r processes="${3}"

  local -r outputDir="$(dirname "${outputFilePath}")"

  local -r confFilePath="${outputDir}/conf.toml"
  createVcfannoConfig "${confFilePath}"

  local args=()
  args+=("-p" "${processes}")
  args+=("${confFilePath}")
  args+=("${inputFilePath}")

  if hasSamples "${inputFilePath}"; then
    singularity exec --bind "/apps,/groups,${TMPDIR}" "${singularityImageDir}/vcfanno.sif" vcfanno "${args[@]}" | singularity exec --bind "/apps,/groups,${TMPDIR}" "${singularityImageDir}/HTSlib.sif" bgzip >"${outputFilePath}"
  else
    # workaround for https://github.com/brentp/vcfanno/issues/123
    singularity exec --bind "/apps,/groups,${TMPDIR}" "${singularityImageDir}/vcfanno.sif" vcfanno "${args[@]}" | cut -f 1-8 | singularity exec --bind "/apps,/groups,${TMPDIR}" "${singularityImageDir}/HTSlib.sif" bgzip >"${outputFilePath}"
  fi
}

# arguments:
#   $1 phenotypes
#   $2 path to output directory
#   $3 path to vibe hdt
#   $4 path to vibe hpo
executeVibe() {
  local -r phenotypes="${1}"
  local -r outputDirPath="${2}"
  local -r vibeHdtPath="${3}"
  local -r vibeHpoPath="${4}"

  declare -A UNIQUE_PHENOTYPES
  get_unique_phenotypes "${phenotypes}"

  local outputFilePath
  for i in "${!UNIQUE_PHENOTYPES[@]}"; do
    outputFilePath="${outputDirPath}/${i//[:]/_}.txt"
    args=()
    args+=("-Djava.io.tmpdir=${TMPDIR}")
    args+=("-XX:ParallelGCThreads=2")
    args+=("-jar" "/opt/vibe/lib/vibe.jar")
    args+=("-t" "${vibeHdtPath}")
    args+=("-w" "${vibeHpoPath}")
    args+=("-p" "$i")
    args+=("-l")
    args+=("-o" "${outputFilePath}")
    singularity exec --bind "/apps,/groups,${TMPDIR}" "${singularityImageDir}/VIBE.sif" java "${args[@]}"

    echo -e "#HPO=$i\n$(cat "${outputFilePath}")" >"${outputFilePath}"
  done
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 assembly
executeAnnotSv() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r assembly="${3}"
  local -r phenotypes="${4}"

  args=()
  args+=("-SVinputFile" "${inputFilePath}")
  args+=("-outputFile" "${outputFilePath}")
  args+=("-genomeBuild" "${assembly}")
  args+=("-annotationMode" "full")
  #FIXME: if we keep the annotations dir apart from the image, then make this path configurable
  args+=("-annotationsDir" "/apps/software/AnnotSV/v3.0.9-GCCcore-7.3.0/share/AnnotSV")

  if [ -n "${phenotypes}" ]; then
    declare -A UNIQUE_PHENOTYPES
    get_unique_phenotypes "${phenotypes}"

    if [[ ${#UNIQUE_PHENOTYPES[@]} -gt 0 ]]; then
      local joinedPhenotypes=$(joinArr "," "${!UNIQUE_PHENOTYPES[@]}")
      args+=("-hpo" "${joinedPhenotypes}")
    fi
  fi
  singularity run --bind /apps,/groups "${singularityImageDir}/AnnotSV.sif" "${args[@]}"
}

# arguments:
#   $1  path to input file
#   $2  path to output file
#   $3  assembly
#   $4  path to reference sequence (optional)
#   $5  vepDirCache
#   $6  vepCodingOnly
#   $7  vepNoIntergenic
#   $8  phenotypes (optional)
#   $9  phenotypeMatching
#   $10 vepHpoGenPhenoFilePath
#   $11 vibeOutputDir (optional)
#   $12 vepPluginInheritanceFilePath (optional)
#   $13 annotSvOutputFilePath (optional)
#   $14 vepPluginPreferredTranscriptFilePath (optional)
#   $15 vepPluginSpliceAiFilePaths (optional)
#   $16 vepPluginVKGLFilePath (optional)
#   $17 vepPluginVKGLMode (optional)
#   $18 vepPluginArtefactFilePath (optional)
#   $19 annVep
#   $20 cpu cores
executeVep() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r assembly="${3}"
  local -r inputRefPath="${4}"
  local -r vepDirCache="${5}"
  local -r vepCodingOnly="${6}"
  local -r vepNoIntergenic="${7}"
  local -r phenotypes="${8}"
  local -r phenotypeMatching="${9}"
  local -r vepHpoGenPhenoFilePath="${10}"
  local -r vibeOutputDir="${11}"
  local -r vepPluginInheritanceFilePath="${12}"
  local -r annotSvOutputFilePath="${13}"
  local -r vepPluginPreferredTranscriptFilePath="${14}"
  local -r vepPluginSpliceAiFilePaths="${15}"
  local -r vepPluginVKGLFilePath="${16}"
  local -r vepPluginVKGLMode="${17}"
  local -r vepPluginArtefactFilePath="${18}"
  local -r annVep="${19}"
  local -r cpuCores="${20}"

  local -r outputDir="$(dirname "${outputFilePath}")"
  mkdir -p "${outputDir}"

  args=()
  args+=("--input_file" "${inputFilePath}" "--format" "vcf")
  args+=("--output_file" "${outputFilePath}" "--vcf")
  args+=("--compress_output" "bgzip")
  args+=("--stats_file" "${outputFilePath}" "--stats_text")
  args+=("--offline" "--cache" "--dir_cache" "${vepDirCache}")
  args+=("--species" "homo_sapiens" "--assembly" "${assembly}")
  args+=("--refseq" "--exclude_predicted")
  args+=("--use_given_ref")
  args+=("--symbol")
  args+=("--flag_pick_allele")
  if [[ "${vepCodingOnly}" == "1" ]]; then
    args+=("--coding_only")
  fi
  if [[ "${vepNoIntergenic}" == "1" ]]; then
    args+=("--no_intergenic")
  fi
  args+=("--af_gnomad" "--pubmed")
  args+=("--shift_3prime" "1")
  args+=("--allele_number")
  args+=("--numbers")
  args+=("--dont_skip")
  args+=("--allow_non_variant")
  args+=("--fork" "${cpuCores}")

  if [ -n "${inputRefPath}" ]; then
    args+=("--fasta" "${inputRefPath}" "--hgvs")
  fi

  # arguments required by CAPICE
  args+=("--regulatory" "--sift" "b" "--polyphen" "b" "--domains" "--canonical" "--total_length")

  args+=("--dir_plugins" "${SCRIPT_DIR}/plugins/vep")
  if [ -n "${phenotypes}" ]; then
    declare -A UNIQUE_PHENOTYPES
    get_unique_phenotypes "${phenotypes}"
    if [[ "${phenotypeMatching}" == "hpo" ]]; then
      args+=("--plugin" "Hpo,${vepHpoGenPhenoFilePath},$(joinArr ";" "${!UNIQUE_PHENOTYPES[@]}")")
    elif [[ "${phenotypeMatching}" == "vibe" ]]; then
      local vibePluginArgs=()
      for i in "${!UNIQUE_PHENOTYPES[@]}"; do
        vibePluginArgs+=("${vibeOutputDir}/${i//[:]/_}.txt")
      done
      args+=("--plugin" "Vibe,$(joinArr ";" "${vibePluginArgs[@]}")")
    fi
  fi
  if [ -n "${vepPluginInheritanceFilePath}" ]; then
    args+=("--plugin" "Inheritance,${vepPluginInheritanceFilePath}")
  fi
  if [ -n "${annotSvOutputFilePath}" ]; then
    args+=("--plugin" "AnnotSV,${annotSvOutputFilePath},AnnotSV_ranking_score;AnnotSV_ranking_criteria;ACMG_class")
  fi
  if [ -n "${vepPluginPreferredTranscriptFilePath}" ]; then
    args+=("--plugin" "PreferredTranscript,${vepPluginPreferredTranscriptFilePath}")
  fi
  if [ -n "${vepPluginVKGLFilePath}" ]; then
    args+=("--plugin" "VKGL,${vepPluginVKGLFilePath},${vepPluginVKGLMode}")
  fi
  if [ -n "${vepPluginArtefactFilePath}" ]; then
    args+=("--plugin" "Artefact,${vepPluginArtefactFilePath}")
  fi
  if [ -n "${vepPluginSpliceAiFilePaths}" ]; then
    local spliceAiFilePathsArr
    IFS=',' read -ra spliceAiFilePathsArr <<<"${vepPluginSpliceAiFilePaths}"
    args+=("--plugin" "SpliceAI,snv=${spliceAiFilePathsArr[0]},indel=${spliceAiFilePathsArr[1]}")
  fi
  if [ -n "${annVep}" ]; then
    # shellcheck disable=SC2206
    args+=(${annVep})
  fi

  singularity exec --bind "/apps,/groups,${TMPDIR}" "${singularityImageDir}/VEP.sif" vep "${args[@]}"
}

# arguments:
#   $1  path to input file
#   $2  path to output file
#   $3  assembly
executeCapice() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r assembly="${3}"

  local -r format="%CHROM\t%POS\t%REF\t%ALT\t%Allele\t%Consequence\t%IMPACT\t%SYMBOL\t%Gene\t%Feature_type\t%Feature\t%BIOTYPE\t%EXON\t%INTRON\t%HGVSc\t%HGVSp\t%cDNA_position\t%CDS_position\t%Protein_position\t%Amino_acids\t%Codons\t%Existing_variation\t%ALLELE_NUM\t%DISTANCE\t%STRAND\t%FLAGS\t%PICK\t%SYMBOL_SOURCE\t%HGNC_ID\t%REFSEQ_MATCH\t%REFSEQ_OFFSET\t%gnomAD_AF\t%gnomAD_AFR_AF\t%gnomAD_AMR_AF\t%gnomAD_ASJ_AF\t%gnomAD_EAS_AF\t%gnomAD_FIN_AF\t%gnomAD_NFE_AF\t%gnomAD_OTH_AF\t%gnomAD_SAS_AF\t%CLIN_SIG\t%SOMATIC\t%PHENO\t%PUBMED\t%CHECK_REF\t%InheritanceModesGene\t%VKGL_CL\t%PolyPhenCat_unknown\t%Domain_ndomain\t%Domain_lcompl\t%motifEScoreChng\t%PolyPhenVal\t%motifEHIPos\t%SIFTval\t%Domain_UD\t%SIFTcat_UD\t%Domain_hmmpanther"

  local -r tmpOutputPath="$(dirname "${outputFilePath}")/split.tsv"

  local args=()
  args+=("+split-vep")
  # Output per transcript/allele consequences on a new line rather than as comma-separated fields on a single line
  args+=("-d")
  args+=("-f" "${format}")
  args+=("-o" "${tmpOutputPath}")
  args+=("${inputFilePath}")

  singularity exec --bind "/apps,/groups,${TMPDIR}" "${singularityImageDir}/BCFtools.sif" bcftools "${args[@]}"

  local -r tmpOutputPath2="$(dirname "${outputFilePath}")/split2.tsv"
  echo -e "##VEP=104.1" > "${tmpOutputPath2}"
  echo -e "${format}" >> "${tmpOutputPath2}"
  cat "${tmpOutputPath}" >> "${tmpOutputPath2}"

  singularity exec --bind "/apps,/groups,${TMPDIR},/home/umcg-dhendriksen/git/capice:/mycapice" "/home/umcg-dhendriksen/git/vip/singularity/CAPICE.sif" python /mycapice/capice.py -i "${tmpOutputPath2}" -o "$(dirname "${outputFilePath}")/test.tsv" -vv
}


main() {
  local -r parsedArguments=$(getopt -a -n pipeline -o i:o:t:c:fkh --long input:,output:,phenotypes:,force,keep,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local inputFilePath=""
  local outputFilePath=""
  local phenotypes=""
  local cfgFilePaths=""
  local force=0
  local keep=0

  eval set -- "${parsedArguments}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      shift
      ;;
    -i | --input)
      inputFilePath=$(realpath "$2")
      shift 2
      ;;
    -o | --output)
      outputFilePath="$2"
      shift 2
      ;;
    -t | --phenotypes)
      phenotypes="$2"
      shift 2
      ;;
    -c | --config)
      cfgFilePaths="$2"
      shift 2
      ;;
    -f | --force)
      force=1
      shift
      ;;
    -k | --keep)
      keep=1
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

  if [[ -z "${inputFilePath}" ]]; then
    echo -e "missing required option -i or --input."
    echo -e "try bash '${SCRIPT_NAME} -h or --help' for more information."
    exit 1
  fi

  local inputRefPath=""
  local cpuCores=""
  local assembly=""
  local phenotypeMatching=""
  local vibeHdtPath=""
  local vibeHpoPath=""
  local vepDirCache=""
  local vepCodingOnly=""
  local vepNoIntergenic=""
  local vepHpoGenPhenoFilePath="${SCRIPT_DIR}/resources/hpo_20210920.tsv"
  local vepPluginInheritanceFilePath="${SCRIPT_DIR}/resources/gene_inheritance_modes_20210920.tsv"
  local vepPluginPreferredTranscriptFilePath=""
  local vepPluginVKGLFilePath=""
  local vepPluginVKGLMode=""
  local vepPluginArtefactFilePath=""
  local vepPluginSpliceAiFilePaths=""
  local annVep=""

  local parseCfgFilePaths="${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePaths}" ]]; then
    parseCfgFilePaths="${parseCfgFilePaths},${cfgFilePaths}"
  fi
  parseCfgs "${parseCfgFilePaths}"

  if [[ -n "${VIP_CFG_MAP["singularity_image_dir"]+unset}" ]]; then
    singularityImageDir="${VIP_CFG_MAP["singularity_image_dir"]}"
  else
    singularityImageDir="${SCRIPT_DIR}/singularity/sif"
  fi

  if [[ -n "${VIP_CFG_MAP["assembly"]+unset}" ]]; then
    assembly="${VIP_CFG_MAP["assembly"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["reference"]+unset}" ]]; then
    inputRefPath="${VIP_CFG_MAP["reference"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["cpu_cores"]+unset}" ]]; then
    cpuCores="${VIP_CFG_MAP["cpu_cores"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_phenotype_matching"]+unset}" ]]; then
    phenotypeMatching="${VIP_CFG_MAP["annotate_phenotype_matching"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vibe_hdt"]+unset}" ]]; then
    vibeHdtPath="${VIP_CFG_MAP["annotate_vibe_hdt"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vibe_hpo"]+unset}" ]]; then
    vibeHpoPath="${VIP_CFG_MAP["annotate_vibe_hpo"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_dir_cache"]+unset}" ]]; then
    vepDirCache="${VIP_CFG_MAP["annotate_vep_dir_cache"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_coding_only"]+unset}" ]]; then
    vepCodingOnly="${VIP_CFG_MAP["annotate_vep_coding_only"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_no_intergenic"]+unset}" ]]; then
    vepNoIntergenic="${VIP_CFG_MAP["annotate_vep_no_intergenic"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_plugin_Hpo"]+unset}" ]]; then
    vepHpoGenPhenoFilePath="${VIP_CFG_MAP["annotate_vep_plugin_Hpo"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_plugin_Inheritance"]+unset}" ]]; then
    vepPluginInheritanceFilePath="${VIP_CFG_MAP["annotate_vep_plugin_Inheritance"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_plugin_PreferredTranscript"]+unset}" ]]; then
    vepPluginPreferredTranscriptFilePath="${VIP_CFG_MAP["annotate_vep_plugin_PreferredTranscript"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_plugin_SpliceAI"]+unset}" ]]; then
    vepPluginSpliceAiFilePaths="${VIP_CFG_MAP["annotate_vep_plugin_SpliceAI"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_plugin_VKGL"]+unset}" ]]; then
    vepPluginVKGLFilePath="${VIP_CFG_MAP["annotate_vep_plugin_VKGL"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_plugin_VKGL_mode"]+unset}" ]]; then
    vepPluginVKGLMode="${VIP_CFG_MAP["annotate_vep_plugin_VKGL_mode"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep_plugin_Artefact"]+unset}" ]]; then
    vepPluginArtefactFilePath="${VIP_CFG_MAP["annotate_vep_plugin_Artefact"]}"
  fi
  if [[ -n "${VIP_CFG_MAP["annotate_vep"]+unset}" ]]; then
    annVep="${VIP_CFG_MAP["annotate_vep"]}"
  fi

  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="$(createOutputPathFromPostfix "${inputFilePath}" "vip_annotate")"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${phenotypes}" "${force}" "${inputRefPath}" "${phenotypeMatching}" "${cpuCores}"
  validateVibe "${vibeHdtPath}" "${vibeHpoPath}"
  validateVep "${vepDirCache}" "${vepCodingOnly}" "${vepNoIntergenic}" "${vepHpoGenPhenoFilePath}" "${vepPluginInheritanceFilePath}" "${vepPluginPreferredTranscriptFilePath}" "${vepPluginSpliceAiFilePaths}" "${vepPluginVKGLFilePath}" "${vepPluginArtefactFilePath}"

  mkdir -p "$(dirname "${outputFilePath}")"
  local -r outputDir="$(realpath "$(dirname "${outputFilePath}")")"
  local -r outputFilename="$(basename "${outputFilePath}")"
  outputFilePath="${outputDir}/${outputFilename}"

  if [[ -f "${outputFilePath}" ]] && [[ "${force}" == "1" ]]; then
    rm "${outputFilePath}"
  fi

  initWorkDir "${outputFilePath}" "${keep}"
  local -r workDir="${VIP_WORK_DIR}"

  local currentInputFilePath="${inputFilePath}" currentOutputFilePath

  # step 1: annotate input with vcfanno
  currentOutputDir="${workDir}/1_vcfanno"
  currentOutputFilePath="${currentOutputDir}/${outputFilename}"
  mkdir -p "${currentOutputDir}"
  executeVcfanno "${currentInputFilePath}" "${currentOutputFilePath}" "${cpuCores}"
  currentInputFilePath="${currentOutputFilePath}"

  # step 3: execute VIBE
  local vibeOutputDir=""
  if [[ -n "${phenotypes}" ]] && [[ "${phenotypeMatching}" == "vibe" ]]; then
    vibeOutputDir="${workDir}/3_vibe"
    mkdir -p "${vibeOutputDir}"
    executeVibe "${phenotypes}" "${vibeOutputDir}" "${vibeHdtPath}" "${vibeHpoPath}"
  fi

  local annotSvOutputFilePath=""
  if containsStructuralVariants "${inputFilePath}"; then
    # step 4: annotate structural variants
    currentOutputDir="${workDir}/4_annotsv"
    currentOutputFilePath="${currentOutputDir}/${outputFilename}"
    mkdir -p "${currentOutputDir}"
    annotSvOutputFilePath="${currentOutputFilePath}.tsv"
    executeAnnotSv "${currentInputFilePath}" "${annotSvOutputFilePath}" "${assembly}" "${phenotypes}"
  fi

  # step 5: execute VEP
  executeVep "${currentInputFilePath}" "${outputFilePath}" "${assembly}" "${inputRefPath}" "${vepDirCache}" "${vepCodingOnly}" "${vepNoIntergenic}" "${phenotypes}" "${phenotypeMatching}" "${vepHpoGenPhenoFilePath}" "${vibeOutputDir}" "${vepPluginInheritanceFilePath}" "${annotSvOutputFilePath}" "${vepPluginPreferredTranscriptFilePath}" "${vepPluginSpliceAiFilePaths}" "${vepPluginVKGLFilePath}" "${vepPluginVKGLMode}" "${vepPluginArtefactFilePath}" "${annVep}" "${cpuCores}"

  currentInputFilePath="${outputFilePath}"
  # step 6: execute CAPICE live scoring
  currentOutputDir="${workDir}/6_capice"
  currentOutputFilePath="${currentOutputDir}/${outputFilename}"
  mkdir -p "${currentOutputDir}"
  executeCapice "${currentInputFilePath}" "${currentOutputFilePath}" "${assembly}"
}

main "${@}"
