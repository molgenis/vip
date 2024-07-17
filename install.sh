#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-a <arg>]
  -u, --url        <arg>    Base download URL (default: https://download.molgeniscloud.org/downloads/vip).
  -a, --assembly   <arg>    Allowed values: GRCh38, ALL (default).
  -n, --no-validate         Disable file checksum checking.
  -h, --help                Print this message and exit."
}

validate() {
  local -r assembly="${1}"
  if [ "${assembly}" != "ALL" ] && [ "${assembly}" != "GRCh37" ] && [ "${assembly}" != "GRCh38" ]; then
    echo -e "invalid assembly value '${assembly}'. valid values are ALL, GRCh37, GRCh38."
    exit 1
  fi
}

# arguments:
#   $1  base url
#   $2  relative url
#   $3  md5 checksum
#   $4  output directory
#   $5  validate
download_file() {
  local -r base_url="${1}"
  local -r relative_url="${2}"
  local -r md5="${3}"
  local -r output_dir="${4}"
  local -r validate="${5}"

  local -r output="${output_dir}/${relative_url}"
  if [ ! -f "${output}" ]; then
    mkdir -p "$(dirname "${output}")"
    local -r url="${base_url}/${relative_url}"

    if ! wget --continue "${url}" --output-document "${output}" --progress=bar:force:noscroll; then
      echo -e "an error occurred downloading ${url}"
        # wget always writes an (empty) output file regardless of errors
        rm -f "${output}"
        exit 1
    fi
  fi

  if [ "${validate}" == "true" ]; then
    echo -e "checking checksum for ${output} ..."
    if ! echo "${md5}"  "${output}" | md5sum --check --quiet --status --strict; then
      echo -e "checksum check failed for '${output}'. remove file and rerun installer to continue"
      exit 1
    fi
  fi
}

# arguments:
#   $1  base url
#   $2  output directory
#   $3  assembly
#   $4  validate
download_files() {
  local -r base_url="${1}"
  local -r output_dir="${2}"
  local -r assembly="${3}"
  local -r validate="${4}"

  # when modifying urls array, please keep list in 'ls -l' order
  local urls=()
  urls+=("51c904d9992c3748d4e266dd883f86f9" "images/annotsv-3.3.6.sif")
  urls+=("7ee92c85e1f4d1151dfe9ae6b1fa06ac" "images/bcftools-1.17.sif")
  urls+=("0879586dfdb49f7cf94d4b9a4c65e2b8" "images/capice-5.1.2.sif")
  urls+=("f050770b830b13cd8befde8deb095b9e" "images/cutesv-2.1.1.sif")
  urls+=("fe0d5bbcf4d3fb7c3331189ed7ddcb2a" "images/deepvariant-1.6.1.sif")
  urls+=("1baf5312d77bdb65fab2f1efec3ba1b7" "images/deepvariant_deeptrio-1.6.1.sif")
  urls+=("78a8ce16c9d8bac53e5fbca4f763dcef" "images/expansionhunter-5.0.0.sif")
  urls+=("afed919dc16ccdae1869cf6dbc5a19d5" "images/fastp-0.23.4.sif")
  urls+=("494c8c9e1031828f48027e34032de423" "images/gado-1.0.3.sif")
  urls+=("d25ba2124ef883b1b6f7a2eff2cb8201" "images/glnexus_v1.4.5-patched.sif")
  urls+=("ff8aceb2c9f185307a69b981ba08efd8" "images/manta-1.6.0.sif")
  urls+=("7486bd5de526d9888df8eea2d8bdea48" "images/minimap2-2.27.sif")
  urls+=("0efcb85f297f08486cd01690b5f13ba0" "images/mosdepth-0.3.8.sif")
  urls+=("06ac8a76a307fa42fffd80ab906fd24b" "images/picard-3.1.1.sif")
  urls+=("9a4b685b26744113d3ea0a3904c02706" "images/samtools-1.17-patch1.sif")
  urls+=("33f84edc86db09103d835748905fca25" "images/seqtk-1.4.sif")
  urls+=("55c190c8ffef22b6cb8ea176f5cf615e" "images/spectre-0.2.1-patched.sif")
  urls+=("8f6e06847776448e004df8b863571109" "images/straglr-1.4.4_vip_v3.sif")
  urls+=("bcc157242cd9b09c66f015c52ef2d61d" "images/stranger-0.8.1.sif")
  urls+=("57401e7b835fed2f52fafadc0dd744d4" "images/vcf-decision-tree-4.1.1.sif")
  urls+=("9c4d7b48138f29651cdd45eb8d0cc4b6" "images/vcf-inheritance-matcher-3.1.0.sif")
  urls+=("7d63b12606eba4775da78b2990a403df" "images/vcf-report-6.1.0.sif")
  urls+=("7bffc236a7c65b2b2e2e5f7d64beaa87" "images/vep-111.0.sif")
  urls+=("82be3c18406e7c027ee4cec83a723d71" "nextflow-24.04.2-all")
  if [ "${assembly}" == "ALL" ] || [ "${assembly}" == "GRCh37" ]; then
    urls+=("11b8eb3d28482729dd035458ad5bda01" "resources/GRCh37/human_g1k_v37.fasta.gz")
    urls+=("772484cc07983aba1355c7fb50f176d4" "resources/GRCh37/human_g1k_v37.fasta.gz.fai")
    urls+=("83871aca19be0df7e3e1a5da3f68d18c" "resources/GRCh37/human_g1k_v37.fasta.gz.gzi")
  fi
  urls+=("55d49c8d95ffc9aee2ec584359c197d2" "resources/GRCh38/AlphScore_final_20230825_stripped_GRCh38.tsv.gz")
  urls+=("c6178d80393254789ebf9c43df6f2d6f" "resources/GRCh38/AlphScore_final_20230825_stripped_GRCh38.tsv.gz.tbi")
  urls+=("8e842bfe9c1eeb0943a588ff5662b9aa" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.dict")
  urls+=("5fddbc109c82980f9436aa5c21a57c61" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai")
  urls+=("aab53048116f541b7aeef2da1c3e4ae7" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz")
  urls+=("5fddbc109c82980f9436aa5c21a57c61" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.fai")
  urls+=("db66bd01c2cb8a1ccb81c486239fa616" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.gzi")
  urls+=("798b74ca2ff85b976ab51aab3f515c69" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.mmi")
  urls+=("c8c50252f1874ce3e7029b2178b2991a" "resources/GRCh38/GCF_000001405.39_GRCh38.p13_genomic_mapped.gff.gz")
  urls+=("16b2f104b5131c643efffbf3a1501ee8" "resources/GRCh38/GRCh38_ncER_perc.bed.gz")
  urls+=("498c22d840476a757be5f5b0e382f8d6" "resources/GRCh38/GRCh38_ncER_perc.bed.gz.tbi")
  urls+=("ad76ef0edeaeb0573775d44864551c54" "resources/GRCh38/capice_model_v5.1.2-v2.ubj")
  urls+=("03d4fb2f5fe500daa77c54455626f8f5" "resources/GRCh38/clinical_repeats.bed")
  urls+=("6ef5212b60bac3f1c9ddf65c276f05a8" "resources/GRCh38/clinvar_20240603_stripped.tsv.gz")
  urls+=("3cbd12a423c808431654f1d8b5a12c84" "resources/GRCh38/clinvar_20240603_stripped.tsv.gz.tbi")
  urls+=("72f12f9ee918878030022c46ec850038" "resources/GRCh38/expansionhunter_variant_catalog.json")
  urls+=("e4c68d0e98a9b5401542b2e8d5b05e82" "resources/GRCh38/gnomad.total.v4.1.sites.stripped.tsv.gz")
  urls+=("eebfca693425c159d87479fef26d3774" "resources/GRCh38/gnomad.total.v4.1.sites.stripped.tsv.gz.tbi")
  urls+=("43858006bdf98145b6fd239490bd0478" "resources/GRCh38/hg38.phyloP100way.bw")
  urls+=("86d75a85add01f940c4d5abc4bd596b9" "resources/GRCh38/human_GRCh38_no_alt_analysis_set.trf.bed")
  urls+=("b01529a38ffe3f3b1a0e5feb5aa23232" "resources/GRCh38/spectre_GCA_000001405.15_GRCh38_no_alt_analysis_set.mdr")
  urls+=("41689e1d397525ec79a511907f55b841" "resources/GRCh38/spectre_grch38_blacklist.bed")
  urls+=("387e88471baa210ea71ad7db5457cc8c" "resources/GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz")
  urls+=("8e9785fe994d0483250109e03344be38" "resources/GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz.tbi")
  urls+=("8e1bc03921ba0b818fe65eba314fa01b" "resources/GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz")
  urls+=("a0f63b592b7b32fe36a9631793f341aa" "resources/GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz.tbi")
  urls+=("644aa23c29f4a9507bae23ef65b936d7" "resources/GRCh38/uORF_5UTR_PUBLIC.txt")
  urls+=("d39fa9cca9fb870b99e6c67b57ef1ad3" "resources/GRCh38/variant_catalog_grch38_fixed.json")
  urls+=("bd235d92bbb731302ad3b34edf6f28a2" "resources/GRCh38/vkgl_consensus_20240401.tsv")
  urls+=("360f56abfe3e2ecb5e224733f948b3be" "resources/GRCh38/GRCh38_FATHMM-MKL_NC.tsv.gz")
  urls+=("53827286f5827d2c2f0e4e6f02179ec2" "resources/GRCh38/GRCh38_FATHMM-MKL_NC.tsv.gz.tbi")
  urls+=("b773b1eb1ef6e03ccdea70dcf736a17f" "resources/GRCh38/GRCh38_GREEN-DB.bed.gz")
  urls+=("7837b9e42da9674e78d9874218f07f00" "resources/GRCh38/GRCh38_GREEN-DB.bed.gz.tbi")
  urls+=("4d725faf3a43d5e40af1568458596aac" "resources/GRCh38/GRCh38_ReMM.tsv.gz")
  urls+=("95c78fce499e8c64f69a3d7780fae377" "resources/GRCh38/GRCh38_ReMM.tsv.gz.tbi")
  urls+=("d149c60680991830056d593543994c56" "resources/annotsv/v3.3.6/2202_hg19.tar.gz")
  urls+=("6c5b6df41efc9a2e348536529a7320de" "resources/annotsv/v3.3.6/2202_phenotype.zip")
  urls+=("354380089157c6f541a9b1af05290c9c" "resources/annotsv/v3.3.6/Annotations_Human_3.3.6.tar.gz")
  urls+=("7683903ac59930d8772505adf3df8a68" "resources/gado/v1.0.4_HPO_v2024-04-04/HPO_2024_04_04_prediction_matrix.cols.txt.gz")
  urls+=("5afc2eb5749e90145e08c424ec250c84" "resources/gado/v1.0.4_HPO_v2024-04-04/HPO_2024_04_04_prediction_matrix.datg")
  urls+=("1769aff19e3b6327fbe1902e7437a34a" "resources/gado/v1.0.4_HPO_v2024-04-04/HPO_2024_04_04_prediction_matrix.rows.txt.gz")
  urls+=("944dfe531af857f3622438a4e00d5f58" "resources/gado/v1.0.4_HPO_v2024-04-04/hp.obo")
  urls+=("a80c7db1a2cb63e42e5bb8a6d8cee2ce" "resources/gado/v1.0.4_HPO_v2024-04-04/genesProteinCoding.txt")
  urls+=("5d4d1c938ff58dbf2d2799a5e4dd06c4" "resources/gado/v1.0.4_HPO_v2024-04-04/HPO_2024_04_04_prediction_info.txt.gz")
  # update utils/install.sh when updating hpo.tsv
  urls+=("42e31fe6e3502fb9bc0b14121f0f844b" "resources/hpo_20240404.tsv")
  # update utils/install.sh when updating inheritance.tsv
  urls+=("df31eb0fe9ebd9ae26c8d6f5f7ba6e57" "resources/inheritance_20240115.tsv")
  urls+=("7138e76a38d6f67935699d06082ecacf" "resources/vep/cache/homo_sapiens_refseq_vep_111_GRCh38.tar.gz")
  # when modifying urls array, please keep list in 'ls -l' order
  for ((i = 0; i < ${#urls[@]}; i += 2)); do
    download_file "${base_url}" "${urls[i+1]}" "${urls[i+0]}" "${output_dir}" "${validate}"
  done
}

extract_files() {
  local -r output_dir="${1}"

  local -r ref_gz="${output_dir}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz"
  local -r ref="${output_dir}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
  if [ ! -f "${ref}" ]; then
    echo -e "extracting ${ref_gz} ..."
    gunzip -c "${ref_gz}" > "${ref}"
  fi

  local -r vep_dir="${output_dir}/resources/vep/cache"
  if [ ! -d "${vep_dir}/homo_sapiens_refseq/111_GRCh38" ]; then
    local -r vep_gz="${vep_dir}/homo_sapiens_refseq_vep_111_GRCh38.tar.gz"
    echo -e "extracting ${vep_gz} ..."
    tar -xzf "${vep_gz}" -C "${vep_dir}"
  fi

  local -r annotsv_dir="${output_dir}/resources/annotsv/v3.3.6"

  local -r annotsv_human_dir="${annotsv_dir}/Annotations_Human"
  if [ ! -d "${annotsv_human_dir}" ]; then
    local -r annotsv_human_gz="${annotsv_dir}/Annotations_Human_3.3.6.tar.gz"
    echo -e "extracting ${annotsv_human_gz} ..."
    tar -xzf "${annotsv_human_gz}" -C "${annotsv_dir}"
  fi

  local -r annotsv_exomiser_dir="${annotsv_dir}/Annotations_Exomiser/2202"
  if [ ! -d "${annotsv_exomiser_dir}/2202_hg19" ]; then
    mkdir -p "${annotsv_exomiser_dir}"
    local -r annotsv_hg19_gz="${annotsv_dir}/2202_hg19.tar.gz"
    echo -e "extracting ${annotsv_hg19_gz} ..."
    tar -xzf "${annotsv_hg19_gz}" -C "${annotsv_exomiser_dir}"
  fi
  if [ ! -d "${annotsv_exomiser_dir}/2202_phenotype" ]; then
    mkdir -p "${annotsv_exomiser_dir}"
    local -r annotsv_phenotype_zip="${annotsv_dir}/2202_phenotype.zip"
    echo -e "extracting ${annotsv_phenotype_zip} ..."
    unzip -qq "${annotsv_phenotype_zip}" -d "${annotsv_exomiser_dir}"
  fi
}

create_symlinks() {
  local -r output_dir="${1}"

  # update utils/install.sh when updating nextflow
  local -r file="nextflow-24.04.2-all"
  (cd "${output_dir}" && chmod +x "${file}") || echo "Failed to set permissions for ${file}"
  (cd "${output_dir}" && rm -f nextflow && ln -s ${file} "nextflow")

  chmod +x "${output_dir}/vip.sh"
  if [ ! -f "${output_dir}/vip" ]; then
    (cd "${output_dir}" && ln -s "vip.sh" "vip")
  fi
}

main() {
  local args=$(getopt -a -n pipeline -o a:u:nh --long assembly:,url:,no-validate,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local assembly="ALL"
  local url="https://download.molgeniscloud.org/downloads/vip"
  local output_dir="${SCRIPT_DIR}"
  local validate="true"

  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      shift
      ;;
    -a | --assembly)
      assembly="$2"
      shift 2
      ;;
    -u | --url)
      url="$2"
      shift 2
      ;;
    -n | --no-validate)
      validate="false"
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

  validate "${assembly}"

  download_files "${url}" "${output_dir}" "${assembly}" "${validate}"
  extract_files "${output_dir}"
  create_symlinks "${output_dir}"
}

main "${@}"

