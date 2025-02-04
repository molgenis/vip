#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "${0}")"

VIP_URL_DATA="${VIP_URL_DATA:-"https://download.molgeniscloud.org/downloads/vip"}"
VIP_DISK_SPACE_REQUIRED_GIGABYTES="280"

if [[ "${#}" -eq "1" ]] && [[ "${*}" == "--help" ]]; then
  echo -e "usage: bash ${SCRIPT_NAME}.sh
  requirements:
    VIP_DIR_DATA environment variable exists
    disk space ${VIP_DISK_SPACE_REQUIRED_GIGABYTES}G for initial install
  environment variables with default values:
    VIP_DIR_DATA ${VIP_DIR_DATA}
    VIP_URL_DATA ${VIP_URL_DATA}"
  exit 0
fi

check_requirements_environment() {
  if [[ -z ${VIP_DIR_DATA+x} ]]; then
    >&2 echo -e "error: environment variable 'VIP_DIR_DATA' is required but could not be found"
    exit 1
  fi

  if [[ -z ${VIP_URL_DATA+x} ]]; then
    >&2 echo -e "error: environment variable 'VIP_URL_DATA' is required but could not be found"
    exit 1
  fi
}

check_requirements_disk_space() {
  if [[ ! -d "${VIP_DIR_DATA}" ]]; then
    if ! mkdir --parents "${VIP_DIR_DATA}" &>/dev/null; then
      >&2 echo -e "error: cannot create directory '${VIP_DIR_DATA}'"
      exit 1
    fi

    local -r disk_space_required_bytes="$((VIP_DISK_SPACE_REQUIRED_GIGABYTES * 1024 * 1024 * 1024))"
    local -r disk_space_available_bytes="$(df --portability --block-size 1 "${VIP_DIR_DATA}" | awk 'NR==2 {print $4}')"

    if [[ "${disk_space_available_bytes}" -lt "${disk_space_required_bytes}" ]]; then
      local -r disk_space_available_human_readable="$(df --portability --human-readable "${VIP_DIR_DATA}" | awk 'NR==2 {print $4}')"
      >&2 echo -e "error: not enough disk space in '${VIP_DIR_DATA}' (${disk_space_available_human_readable} < ${VIP_DISK_SPACE_REQUIRED_GIGABYTES}G)"
      rm -r "${VIP_DIR_DATA}"
      exit 1
    fi
  fi
}

check_requirements() {
  check_requirements_environment
  check_requirements_disk_space
}

postprocess_samtools() {
  echo -e "postprocessing samtools"
}

# arguments:
#   $1  md5 checksum
#   $2  relative url
#   $3  postprocess function name or empty string
install_file() {
  local -r md5="${1}"
  local -r url_relative="${2}"
  local -r postprocess_fn="${3}"

  local -r file_url="${VIP_URL_DATA}/${url_relative}"
  local -r file="${VIP_DIR_DATA}/${url_relative}"

  local -r file_dir="$(dirname "${file}")"
  if [[ ! -d "${file_dir}" ]]; then
    mkdir -p "${file_dir}"
  fi

  # download file and validate checksum on the fly
  if ! curl --fail --silent --location "${file_url}" | tee "${file}" | md5sum --check --quiet --status --strict <(echo "${md5}  -"); then
    local -r exit_codes=("${PIPESTATUS[@]}")
    if [[ "${exit_codes[0]}" -ne 0 ]]; then
      >&2 echo -e "error: download '${file_url}' failed"
     exit 1
    fi
    if [[ "${exit_codes[2]}" -ne 0 ]]; then
      >&2 echo -e "error: checksum check failed for '${file}'"
     exit 1
    fi
    exit 1
  fi

  # perform postprocessing
  if [[ -n "${postprocess_fn}" ]]; then
    # call postprocessing function
    ${postprocess_fn} "${file}"
  fi
}

# arguments:
#   $1  file
postprocess_nextflow() {
  local -r file="${1}"
  chmod +x "${file}"
}

# arguments:
#   $1  file
postprocess_annotsv_hg19() {
  local -r file="${1}"
  local -r file_basename="$(basename "${file}")"
  local -r dir="$(dirname "${file}")/Annotations_Exomiser/${file_basename%%_*}"
  mkdir -p "${dir}"
  tar --extract --gzip --file "${file}" --directory "${dir}"
  rm "${file}"
}

# arguments:
#   $1  file
postprocess_annotsv_phenotype() {
  local -r file="${1}"
  local -r file_basename="$(basename "${file}")"
  local -r dir="$(dirname "${file}")/Annotations_Exomiser/${file_basename%%_*}"
  mkdir -p "${dir}"
  unzip -qq "${file}" -d "${dir}"
  rm "${file}"
}

# arguments:
#   $1  file
postprocess_annotsv_annotations() {
  local -r file="${1}"
  local -r dir="$(dirname "${file}")"
  tar --extract --gzip --file "${file}" --directory "${dir}"
  rm "${file}"
}

# arguments:
#   $1  file
postprocess_reference_genome() {
  local -r file="${1}"
  local -r file_extracted=${file%".gz"}
  gunzip -c "${file}" > "${file_extracted}"
}

# arguments:
#   $1  file
postprocess_vep() {
  local -r file="${1}"
  local -r dir="$(dirname "${file}")"
  tar --extract --gzip --file "${file}" --directory "${dir}"
  rm "${file}"
}

install_files() {
  # parse database to determine files to install
  local -r vip_install_db_file="${VIP_DIR_DATA}/install.db"
  declare -A vip_install_db
  if [[ -f "${vip_install_db_file}" ]]; then
    while IFS= read -r; do
      vip_install_db["${REPLY}"]="INSTALLED"
    done <"${vip_install_db_file}"
  else
    # create new database
    touch "${vip_install_db_file}"
  fi

  # when modifying data array, please keep list in 'ls -l' order
  local data=()
  data+=("2c21479ee78b1b6eac25dc993511af0c" "images/annotsv-3.4.4.sif" "")
  data+=("40594154f81dec76779ffa5d5e3ad052" "images/bcftools-1.20.sif" "")
  data+=("0879586dfdb49f7cf94d4b9a4c65e2b8" "images/capice-5.1.2.sif" "")
  data+=("bc4be7f94aa38add1bf4cfe2a41a1f02" "images/cutesv-2.1.1_v2.sif" "")
  data+=("fe0d5bbcf4d3fb7c3331189ed7ddcb2a" "images/deepvariant-1.6.1.sif" "")
  data+=("1baf5312d77bdb65fab2f1efec3ba1b7" "images/deepvariant_deeptrio-1.6.1.sif" "")
  data+=("47396916f1940bff61ad092cbfda3bd2" "images/expansionhunter-5.0.0_v2.sif" "")
  data+=("63f1fb267d471b04898d004152b97fb0" "images/fastp-0.23.4_v2.sif" "")
  data+=("816afd127e42a4b30a2b9679afa326ae" "images/gado-1.0.3_v2.sif" "")
  data+=("d25ba2124ef883b1b6f7a2eff2cb8201" "images/glnexus_v1.4.5-patched.sif" "")
  data+=("ff8aceb2c9f185307a69b981ba08efd8" "images/manta-1.6.0.sif" "")
  data+=("4d9e2b22fc5e4216e05a715dd3e5eb02" "images/minimap2-2.27_v2.sif" "")
  data+=("0efcb85f297f08486cd01690b5f13ba0" "images/mosdepth-0.3.8.sif" "")
  data+=("17d677e462bb14d002efa5ea6f88c677" "images/picard-3.1.1_v2.sif" "")
  data+=("9a4b685b26744113d3ea0a3904c02706" "images/samtools-1.17-patch1.sif" "")
  data+=("ccbb1e1887f11d9e3cda1ae8bf2d67da" "images/seqtk-1.4_v2.sif" "")
  data+=("4d58cc7a4e3e497a245095a62562e27e" "images/spectre-0.2.1-patched_v2.sif" "")
  data+=("a11f9e4a1288d92963d63c9d8bfe3a1d" "images/straglr-1.4.5-vip-v1.sif" "")
  data+=("8d55b74c7f27785824874bca5a88ffd2" "images/stranger-0.9.3.sif" "")
  data+=("b3251b3329e92d5c67b383353d3d3f5d" "images/vcf-decision-tree-5.1.3.sif" "")
  data+=("5cc8e497f1ed2da8d284357aa97db7d6" "images/vcf-inheritance-matcher-3.3.6.sif" "")
  data+=("9357590531fd4f1af1ab610ddafbdd3b" "images/vcf-report-7.2.0.sif" "")
  data+=("7bffc236a7c65b2b2e2e5f7d64beaa87" "images/vep-111.0.sif" "")
  data+=("d036cf4af4538f5f14dd99aae46cfca5" "images/whatshap-2.4.sif" "")
  data+=("4db012dfaa1ed91371b73e3ab338aaad" "nextflow-24.10.3-dist" "postprocess_nextflow")
  data+=("d9083115672ba278a0ad9baf01f747b3" "resources/annotsv/v3.4.4/2309_hg19.tar.gz" "postprocess_annotsv_hg19")
  data+=("ae755bea21ad8750ecd12a510104a889" "resources/annotsv/v3.4.4/2309_phenotype.zip" "postprocess_annotsv_phenotype")
  data+=("a0a4df58d3ed719121d935d1a28f363c" "resources/annotsv/v3.4.4/Annotations_Human_3.4.4.tar.gz" "postprocess_annotsv_annotations")
  data+=("25d79667ba41aef0a418f75468e4b457" "resources/annotsv/v3.4.4/jar/exomiser-rest-prioritiser-12.1.0.jar" "")
  data+=("94bac97fe4dbc4ad1a74bde3afb55603" "resources/gado/v1.0.4_HPO_v2024-08-13/HPO_2024_08_13_prediction_matrix.cols.txt.gz" "")
  data+=("4461c232ae1be508e7aa1fb44ade2292" "resources/gado/v1.0.4_HPO_v2024-08-13/HPO_2024_08_13_prediction_matrix.datg" "")
  data+=("6d50fbb9b2f74221265dede2aae13e71" "resources/gado/v1.0.4_HPO_v2024-08-13/HPO_2024_08_13_prediction_matrix.rows.txt.gz" "")
  data+=("31788f6a17183a5da370f338b808e325" "resources/gado/v1.0.4_HPO_v2024-08-13/hp.obo" "")
  data+=("da5e5e6fefd338d8224b1c075ae4aa74" "resources/gado/v1.0.4_HPO_v2024-08-13/genesProteinCoding.txt" "")
  data+=("74b9abc9a94c81fc27393e2f77ad498b" "resources/gado/v1.0.4_HPO_v2024-08-13/HPO_2024_08_13_prediction_info.txt.gz" "")
  data+=("55d49c8d95ffc9aee2ec584359c197d2" "resources/GRCh38/AlphScore_final_20230825_stripped_GRCh38.tsv.gz" "")
  data+=("c6178d80393254789ebf9c43df6f2d6f" "resources/GRCh38/AlphScore_final_20230825_stripped_GRCh38.tsv.gz.tbi" "")
  data+=("fbfbaa3e90c2888823f0e17ce631396e" "resources/GRCh38/capice_model_v5.1.2-v4.ubj" "")
  data+=("03d4fb2f5fe500daa77c54455626f8f5" "resources/GRCh38/clinical_repeats.bed" "")
  data+=("8da13608d59915f031beade9c3981c2e" "resources/GRCh38/clinvar_20241126-stripped.tsv.gz" "")
  data+=("6b1ed6d55e870e37d2bed360abc26fe2" "resources/GRCh38/clinvar_20241126-stripped.tsv.gz.tbi" "")
  data+=("475443a10a2672295574ed4a23fd4c62" "resources/GRCh38/default_exon_20250122.bed" "")
  data+=("9ed22dfd2fdddfcaf0c4696e2dcab6eb" "resources/GRCh38/default_gene_20250122.bed" "")
  data+=("72f12f9ee918878030022c46ec850038" "resources/GRCh38/expansionhunter_variant_catalog.json" "")
  data+=("8e842bfe9c1eeb0943a588ff5662b9aa" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.dict" "")
  data+=("5fddbc109c82980f9436aa5c21a57c61" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai" "")
  data+=("aab53048116f541b7aeef2da1c3e4ae7" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz" "postprocess_reference_genome")
  data+=("5fddbc109c82980f9436aa5c21a57c61" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.fai" "")
  data+=("db66bd01c2cb8a1ccb81c486239fa616" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.gzi" "")
  data+=("798b74ca2ff85b976ab51aab3f515c69" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.mmi" "")
  data+=("c8c50252f1874ce3e7029b2178b2991a" "resources/GRCh38/GCF_000001405.39_GRCh38.p13_genomic_mapped.gff.gz" "")
  data+=("360f56abfe3e2ecb5e224733f948b3be" "resources/GRCh38/GRCh38_FATHMM-MKL_NC.tsv.gz" "")
  data+=("53827286f5827d2c2f0e4e6f02179ec2" "resources/GRCh38/GRCh38_FATHMM-MKL_NC.tsv.gz.tbi" "")
  data+=("b773b1eb1ef6e03ccdea70dcf736a17f" "resources/GRCh38/GRCh38_GREEN-DB.bed.gz" "")
  data+=("7837b9e42da9674e78d9874218f07f00" "resources/GRCh38/GRCh38_GREEN-DB.bed.gz.tbi" "")
  data+=("16b2f104b5131c643efffbf3a1501ee8" "resources/GRCh38/GRCh38_ncER_perc.bed.gz" "")
  data+=("498c22d840476a757be5f5b0e382f8d6" "resources/GRCh38/GRCh38_ncER_perc.bed.gz.tbi" "")
  data+=("e4c68d0e98a9b5401542b2e8d5b05e82" "resources/GRCh38/gnomad.total.v4.1.sites.stripped.tsv.gz" "")
  data+=("eebfca693425c159d87479fef26d3774" "resources/GRCh38/gnomad.total.v4.1.sites.stripped.tsv.gz.tbi" "")
  data+=("43858006bdf98145b6fd239490bd0478" "resources/GRCh38/hg38.phyloP100way.bw" "")
  data+=("86d75a85add01f940c4d5abc4bd596b9" "resources/GRCh38/human_GRCh38_no_alt_analysis_set.trf.bed" "")
  data+=("2f8c8fcc75ea29f6798621d0446fe194" "resources/GRCh38/ReMM.v0.4.hg38.tsv.gz" "")
  data+=("c477b123abbe72c4aa66bf3abc18d9ab" "resources/GRCh38/ReMM.v0.4.hg38.tsv.gz.tbi" "")
  data+=("b01529a38ffe3f3b1a0e5feb5aa23232" "resources/GRCh38/spectre_GCA_000001405.15_GRCh38_no_alt_analysis_set.mdr" "")
  data+=("41689e1d397525ec79a511907f55b841" "resources/GRCh38/spectre_grch38_blacklist.bed" "")
  data+=("387e88471baa210ea71ad7db5457cc8c" "resources/GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz" "")
  data+=("8e9785fe994d0483250109e03344be38" "resources/GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz.tbi" "")
  data+=("8e1bc03921ba0b818fe65eba314fa01b" "resources/GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz" "")
  data+=("a0f63b592b7b32fe36a9631793f341aa" "resources/GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz.tbi" "")
  data+=("644aa23c29f4a9507bae23ef65b936d7" "resources/GRCh38/uORF_5UTR_PUBLIC.txt" "")
  data+=("d39fa9cca9fb870b99e6c67b57ef1ad3" "resources/GRCh38/variant_catalog_grch38_fixed.json" "")
  data+=("ef2716679b0d9dca9df4b67af821f6f9" "resources/GRCh38/vkgl_consensus_20241001.tsv" "")
  data+=("d94140e762dfc6da23011718cccf2609" "resources/hpo_20240813.tsv" "")
  data+=("b62d33e85321a3104e58c129232e98df" "resources/hpo_20240813_phenotypic_abnormality.tsv" "")
  data+=("ff9677b7756d4d6901441aad6a6e0f49" "resources/inheritance_20250131.tsv" "")
  data+=("7138e76a38d6f67935699d06082ecacf" "resources/vep/cache/homo_sapiens_refseq_vep_111_GRCh38.tar.gz" "postprocess_vep")
  data+=("4023abed0bccb31bf18bde3ddd1f2ed6" "resources/vip-report-template-v7.1.1.html" "")

  for ((i = 0; i < ${#data[@]}; i += 3)); do
    if [[ ! "${vip_install_db["${data[i+1]}"]+_}" ]]; then
      install_file "${data[i+0]}" "${data[i+1]}" "${data[i+2]}"

       # update database
       echo -e "${data[i+1]}" >> "${vip_install_db_file}"
    fi
  done
}

main() {
  #validate arguments
  if [[ "${#}" -ne 0 ]]; then
    >&2 echo "error: invalid arguments '${*}', see 'bash ${SCRIPT_NAME} --help' for more information"
    exit 1
  fi

  check_requirements
  install_files
}

main "${@}"
