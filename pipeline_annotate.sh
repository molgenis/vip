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

-c, --config     <arg>    optional: Configuration file (.cfg)
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
  annotate_vep_plugin_SpliceAI            VEP: Comma-separated paths to SpliceAI snv and indel files
  annotate_vep                            Variant Effect Predictor (VEP) options.
  assembly                                see 'bash pipeline.sh --help' for usage.
  reference                               see 'bash pipeline.sh --help' for usage.
  cpu_cores                               see 'bash pipeline.sh --help' for usage."
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

#######################################
# Filter non-SV records without CAPICE score
#
# Arguments:
#   path to input VCF file
#   path to output VCF file
#   number of worker threads
#######################################
filterUnscoredCapiceRecords() {
  echo -e "filtering records without CAPICE score ..."

  local -r inputVcf="$1"
  local -r outputVcf="$2"
  local -r threads="$3"

  local filter
  if containsStructuralVariants "${inputVcf}"; then
    filter="(CAP=\".\" && SVTYPE=\".\")"
  else
    filter="CAP=\".\""
  fi

  local args=()
  args+=("filter")
  args+=("-i" "${filter}")
  args+=("-o" "${outputVcf}")
  args+=("-O" "z")
  args+=("--no-version")
  args+=("--threads" "${threads}")
  args+=("${inputVcf}")

  module load "${MOD_BCF_TOOLS}"
  bcftools "${args[@]}"
  module purge

  echo -e "filtering records without CAPICE score done"
}

# arguments:
#   $1 vepDirCache
#   $2 vepCodingOnly
#   $3 vepNoIntergenic
#   $4 vepHpoGenPhenoFilePath
#   $5 vepPluginInheritanceFilePath
#   $6 vepPluginPreferredTranscriptFilePath
#   $7 vepPluginSpliceAiFilePaths
validateVep() {
  local -r vepDirCache="${1}"
  local -r vepCodingOnly="${2}"
  local -r vepNoIntergenic="${3}"
  local -r vepHpoGenPhenoFilePath="${4}"
  local -r vepPluginInheritanceFilePath="${5}"
  local -r vepPluginPreferredTranscriptFilePath="${6}"
  local -r vepPluginSpliceAiFilePaths="${7}"

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

  if [[ -n "${referencePath}" ]] && [[ ! -f "${referencePath}" ]]; then
    echo -e "${referencePath} does not exist."
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
file="/apps/data/VKGL/${assembly}/vkgl_consensus_jan2021_normalized.vcf.gz"
fields = ["VKGL_CL", "AMC", "EMC", "LUMC", "NKI", "RMMC", "UMCG", "UMCU", "VUMC"]
ops=["self","self","self","self","self","self","self","self","self"]
names=["VKGL", "VKGL_AMC", "VKGL_EMC", "VKGL_LUMC", "VKGL_NKI", "VKGL_RMMC", "VKGL_UMCG", "VKGL_UMCU", "VKGL_VUMC"]

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

[[annotation]]
file="/apps/data/UMCG/MVL/${assembly}/Artefact_Totaal-Molecular_variants-2020-10-08_07-49-09_normalized.vcf.gz"
fields = ["MVL"]
ops=["self"]
names=["MVLA"]
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
    module load "${MOD_VCF_ANNO}"
    module load "${MOD_HTS_LIB}"

    vcfanno "${args[@]}" | bgzip >"${outputFilePath}"

    module purge
  else
    # workaround for https://github.com/brentp/vcfanno/issues/123
    module load "${MOD_VCF_ANNO}"
    module load "${MOD_HTS_LIB}"

    vcfanno "${args[@]}" | cut -f 1-8 | bgzip >"${outputFilePath}"
    module purge
  fi
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 assembly
#   $4 cpu cores
executeCadd() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r assembly="${3}"
  local -r cpuCores="${4}"

  module load "${MOD_HTS_LIB}"

  local -r outputDir="$(dirname "${outputFilePath}")"

  # strip headers from input vcf for CADD
  local -r headerlessInputFilePath="${outputDir}/headerless_$(basename "${inputFilePath}")"
  gunzip -c "${inputFilePath}" | sed '/^#/d' | bgzip >"${headerlessInputFilePath}"
  module purge

  # do not log usage information (which is logged to stderr instead of stdout)
  module load "${MOD_CADD}" 2>/dev/null

  args=()
  args+=("-a")
  args+=("-g" "${assembly}")
  args+=("-o" "${outputFilePath}")
  args+=("-c" "${cpuCores}")
  args+=("-s" "${headerlessInputFilePath}")
  args+=("-t" "${TMPDIR}")

  CADD.sh "${args[@]}"
  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 assembly
executeCapicePredict() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r assembly="${3}"

  module load "${MOD_CAPICE}"

  args=()
  args+=("${EBROOTCAPICE}/CAPICE_scripts/model_inference.py")
  args+=("--input_path" "${inputFilePath}")
  args+=("--model_path" "${EBROOTCAPICE}/CAPICE_model/${assembly}/xgb_booster.pickle.dat")
  args+=("--prediction_savepath" "${outputFilePath}")
  # only log stderr
  python "${args[@]}" 1>/dev/null
  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
executeCapiceVcf() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"

  module load "${MOD_CAPICE}"

  args=()
  args+=("-Djava.io.tmpdir=${TMPDIR}")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx1g")
  args+=("-jar" "${EBROOTCAPICE}/capice2vcf.jar")
  args+=("-i" "${inputFilePath}")
  args+=("-o" "${outputFilePath}")

  java "${args[@]}"
  module purge
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 path to annotation file
#   $4 processes
executeCapiceAnnotate() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r annotationFilePath="${3}"
  local -r processes="${4}"

  local -r outputDir="$(dirname "${outputFilePath}")"

  local -r confFilePath="${outputDir}/conf.toml"
  cat >"${confFilePath}" <<EOT
[[annotation]]
file="${annotationFilePath}"
fields = ["CAP"]
ops=["self"]
names=["CAP"]
EOT

  args=()
  args+=("-p" "${processes}")
  args+=("${confFilePath}")
  args+=("${inputFilePath}")

  if hasSamples "${inputFilePath}"; then
    module load "${MOD_VCF_ANNO}"
    module load "${MOD_HTS_LIB}"

    vcfanno "${args[@]}" | bgzip >"${outputFilePath}"

    module purge
  else
    # workaround for https://github.com/brentp/vcfanno/issues/123
    module load "${MOD_VCF_ANNO}"
    module load "${MOD_HTS_LIB}"

    vcfanno "${args[@]}" | cut -f 1-8 | bgzip >"${outputFilePath}"
    module purge
  fi
}

# arguments:
#   $1 path to input file
#   $2 path to output file
#   $3 assembly
#   $4 cpu cores
executeCapice() {
  local -r inputFilePath="${1}"
  local -r outputFilePath="${2}"
  local -r assembly="${3}"
  local -r cpuCores="${4}"

  local -r outputDir="$(dirname "${outputFilePath}")"
  local -r outputFilename="$(basename "${outputFilePath}")"

  local currentInputFilePath="${inputFilePath}"
  local currentOutputDir="${outputDir}/1_filter_unscored"
  local currentOutputFilePath="${currentOutputDir}/${outputFilename}"
  mkdir -p "${currentOutputDir}"
  filterUnscoredCapiceRecords "${currentInputFilePath}" "${currentOutputFilePath}" "${cpuCores}"

  if [[ "${assembly}" == GRCh37 ]]; then
    if [[ "$(zgrep -c -m 1 "^[^#]" "${currentOutputFilePath}")" -eq 0 ]]; then
      echo -e "skipping CAPICE execution because all variants have precomputed scores ..."
      cd "${outputDir}" || exit
      ln -s "${currentInputFilePath}" "${outputFilename}"
    else
      currentInputFilePath="${currentOutputFilePath}"
      currentOutputDir="${outputDir}/2_cadd"
      currentOutputFilePath="${currentOutputDir}/${outputFilename}"
      mkdir -p "${currentOutputDir}"
      executeCadd "${currentInputFilePath}" "${currentOutputFilePath}" "${assembly}" "${cpuCores}"

      if [[ "$(zgrep -c -m 1 "^[^#]" "${currentOutputFilePath}")" -eq 0 ]]; then
        echo -e "skipping CAPICE execution because there are no CADD scores ..."
        cd "${outputDir}" || exit
        ln -s "${currentInputFilePath}" "${outputFilename}"
      else
        currentInputFilePath="${currentOutputFilePath}"
        currentOutputDir="${outputDir}/3_capice_predict"
        currentOutputFilePath="${currentOutputDir}/${outputFilename}.tsv"
        mkdir -p "${currentOutputDir}"
        executeCapicePredict "${currentInputFilePath}" "${currentOutputFilePath}" "${assembly}"

        currentInputFilePath="${currentOutputFilePath}"
        currentOutputDir="${outputDir}/4_capice2vcf"
        currentOutputFilePath="${currentOutputDir}/${outputFilename}"
        mkdir -p "${currentOutputDir}"
        executeCapiceVcf "${currentInputFilePath}" "${currentOutputFilePath}" "${assembly}"

        annotationFilePath="${currentOutputFilePath}"
        currentOutputDir="${outputDir}/5_vcfanno"
        currentOutputFilePath="${currentOutputDir}/${outputFilename}"
        mkdir -p "${currentOutputDir}"
        executeCapiceAnnotate "${inputFilePath}" "${currentOutputFilePath}" "${annotationFilePath}" "${cpuCores}"

        cd "${outputDir}" || exit
        ln -s "${currentOutputFilePath}" "${outputFilename}"
      fi
    fi
  else
    echo -e "Skipping capice for ${assembly}"
    cd "${outputDir}" || exit
    ln -s "${currentInputFilePath}" "${outputFilename}"
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

  module load "${MOD_VIBE}"

  declare -A UNIQUE_PHENOTYPES
  get_unique_phenotypes "${phenotypes}"

  local outputFilePath
  for i in "${!UNIQUE_PHENOTYPES[@]}"; do
    outputFilePath="${outputDirPath}/${i//[:]/_}.txt"
    args=()
    args+=("-Djava.io.tmpdir=${TMPDIR}")
    args+=("-XX:ParallelGCThreads=2")
    args+=("-jar" "${EBROOTVIBE}/vibe.jar")
    args+=("-t" "${vibeHdtPath}")
    args+=("-w" "${vibeHpoPath}")
    args+=("-p" "$i")
    args+=("-l")
    args+=("-o" "${outputFilePath}")
    java "${args[@]}"

    echo -e "#HPO=$i\n$(cat "${outputFilePath}")" >"${outputFilePath}"
  done
  module purge
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

  module load "${MOD_ANNOTSV}"

  args=()
  args+=("-SVinputFile" "${inputFilePath}")
  args+=("-outputFile" "${outputFilePath}")
  args+=("-genomeBuild" "${assembly}")
  args+=("-typeOfAnnotation" "split")

  if [ -n "${phenotypes}" ]; then
    declare -A UNIQUE_PHENOTYPES
    get_unique_phenotypes "${phenotypes}"

    if [[ ${#UNIQUE_PHENOTYPES[@]} -gt 0 ]]; then
      local joinedPhenotypes=$(joinArr "," "${!UNIQUE_PHENOTYPES[@]}")
      args+=("-hpo" "${joinedPhenotypes}")
    fi
  fi
  ${EBROOTANNOTSV}/bin/AnnotSV "${args[@]}"

  module purge
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
#   $16 annVep
#   $17 cpu cores
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
  local -r annVep="${16}"
  local -r cpuCores="${17}"

  local -r outputDir="$(dirname "${outputFilePath}")"
  mkdir -p "${outputDir}"

  module load "${MOD_VEP}"
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
    args+=("--plugin" "AnnotSV,${annotSvOutputFilePath},AnnotSV_ranking;ranking_decision_criteria")
  fi
  if [ -n "${vepPluginPreferredTranscriptFilePath}" ]; then
    args+=("--plugin" "PreferredTranscript,${vepPluginPreferredTranscriptFilePath}")
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

  vep "${args[@]}"
  module purge
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
  local cfgFilePath=""
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
      cfgFilePath=$(realpath "$2")
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
  local vepHpoGenPhenoFilePath="${SCRIPT_DIR}/resources/hpo_20210308.tsv"
  local vepPluginInheritanceFilePath="${SCRIPT_DIR}/resources/gene_inheritance_modes_20210309.tsv"
  local vepPluginPreferredTranscriptFilePath=""
  local vepPluginSpliceAiFilePaths=""
  local annVep=""

  parseCfg "${SCRIPT_DIR}/config/default.cfg"
  if [[ -n "${cfgFilePath}" ]]; then
    parseCfg "${cfgFilePath}"
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
  if [[ -n "${VIP_CFG_MAP["annotate_vep"]+unset}" ]]; then
    annVep="${VIP_CFG_MAP["annotate_vep"]}"
  fi

  if [[ -z "${outputFilePath}" ]]; then
    outputFilePath="$(createOutputPathFromPostfix "${inputFilePath}" "vip_annotate")"
  fi

  validate "${inputFilePath}" "${outputFilePath}" "${phenotypes}" "${force}" "${inputRefPath}" "${phenotypeMatching}" "${cpuCores}"
  validateVibe "${vibeHdtPath}" "${vibeHpoPath}"
  validateVep "${vepDirCache}" "${vepCodingOnly}" "${vepNoIntergenic}" "${vepHpoGenPhenoFilePath}" "${vepPluginInheritanceFilePath}" "${vepPluginPreferredTranscriptFilePath}" "${vepPluginSpliceAiFilePaths}"

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

  # step 2: annotate input with CAPICE
  currentOutputDir="${workDir}/2_capice"
  currentOutputFilePath="${currentOutputDir}/${outputFilename}"
  mkdir -p "${currentOutputDir}"
  executeCapice "${currentInputFilePath}" "${currentOutputFilePath}" "${assembly}" "${cpuCores}"
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
  executeVep "${currentInputFilePath}" "${outputFilePath}" "${assembly}" "${inputRefPath}" "${vepDirCache}" "${vepCodingOnly}" "${vepNoIntergenic}" "${phenotypes}" "${phenotypeMatching}" "${vepHpoGenPhenoFilePath}" "${vibeOutputDir}" "${vepPluginInheritanceFilePath}" "${annotSvOutputFilePath}" "${vepPluginPreferredTranscriptFilePath}" "${vepPluginSpliceAiFilePaths}" "${annVep}" "${cpuCores}"
}

main "${@}"
