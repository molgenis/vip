#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "${0}")"

VIP_URL_DATA="${VIP_URL_DATA:-"https://download.molgeniscloud.org/downloads/vip"}"
VIP_DISK_SPACE_REQUIRED_GIGABYTES="280"

usage() {
  echo -e "usage: bash ${SCRIPT_NAME}.sh [-v <vip_version>] [-d <data_dir>] [-u <url>] [-p]
  -p, --prune     remove resources from previous VIP installs that are not required for this version.
  -u, --url       base url to download VIP resources from
  -d, --data_dir  directory where VIP resources should be installed
  -v, --version   VIP version to be installed
  -h, --help

  requirements:
    VIP_DIR_DATA environment variable exists
    disk space ${VIP_DISK_SPACE_REQUIRED_GIGABYTES}G for initial install
  environment variables with default values:
    VIP_VER      ${VIP_VER}
    VIP_DIR_DATA ${VIP_DIR_DATA}
    VIP_URL_DATA ${VIP_URL_DATA}
  if --data and/or --url are not provided."
  exit 0
}


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
  VIP_VER=$1;
  is_prune_enabled=$2;

  # parse database to determine files to install
  local -r vip_install_db_file="${VIP_DIR_DATA}/install.db"
  declare -A vip_install_db
  if [[ -f "${vip_install_db_file}" ]]; then
    # shellcheck disable=SC2034
    while read -r resource version; do
      vip_install_db["${resource}"]="INSTALLED"
    done <"${vip_install_db_file}"
  else
    # create new database
    touch "${vip_install_db_file}"
  fi

  # when modifying data array, please keep list in 'ls -l' order
  local data=()
  data+=("e58485115ae8a0030f77764bc27896cc" "images/annotsv-3.5.10.sif" "")
  data+=("37826d138d91514860049824771f2dea" "images/bcftools-1.25.sif" "")
  data+=("9d32f3b6ba25606ec1dbc40d4a31b9db" "images/capice-5.1.2+build.2.sif" "")
  data+=("15072899ae836f55a61b4c7cf95dd3a9" "images/cutesv-2.1.4.sif" "")
  data+=("28937e8a97287c85b030d43e9362fecc" "images/deepvariant-1.10.0.sif" "")
  data+=("bf91f77bd18989d13c2d631a6be09f5a" "images/deepvariant_deeptrio-1.10.0.sif" "")
  data+=("dadd008a701277a002621f9cd6ef35cb" "images/expansionhunter-5.0.0+build.4.sif" "")
  data+=("04ef0fc1052fe8e6e20ccd75948da785" "images/fastp-1.4.0.sif" "")
  data+=("dba3b024cfd1253f569695eab91905b0" "images/gado-1.0.3+build.4.sif" "")
  data+=("355949eba41557fbee83a2711800115c" "images/gatk-4.7.0.0.sif" "")
  data+=("d25ba2124ef883b1b6f7a2eff2cb8201" "images/glnexus_v1.4.5-patched.sif" "")
  data+=("bc731b5fad6c75a1bc81b9afb75c06ca" "images/happy-0.3.15.sif" "")
  data+=("7718ec9b21b13b089bb31e7b97731dc1" "images/manta-1.6.0+build.2.sif" "")
  data+=("e1849a9d514f8554227b19658a524863" "images/minimap2-2.31.build1.sif" "")
  data+=("6cb080478cee636b8190b44a12a1a10a" "images/mosdepth-0.3.14--h87be163_2.sif" "")
  data+=("75850e5f88c1e95b88f9a375aba100c0" "images/picard-3.5.0.sif" "")
  data+=("12c3ad0c65d9691a33b20678ab5971bb" "images/samtools-1.25.sif" "")
  data+=("13324a1baf3a5dde5f05174a6b58a9be" "images/seqtk-1.5.build1.sif" "")
  data+=("e202150aab4a8c757a10eb3745b46518" "images/spectre-0.2.1+9058094.build1.sif" "")
  data+=("1e3bd6c9df707f06dbd35916dee6e3bd" "images/straglr-1.5.6+build.2.sif" "")
  data+=("644b7886fd53c31f38d579ae687e8afd" "images/straglr-tsv2vcf-1.2.1.build1.sif" "")
  data+=("f58a0a3085da678573f609ac22d63ce7" "images/stranger-0.10.2.sif" "")
  data+=("c106c1cdd59ddf518f584d859d8c8d58" "images/vcf-decision-tree-6.0.5.build1.sif" "")
  data+=("96d07ce160b35abec10f3246cca4769b" "images/vcf-inheritance-matcher-4.0.2.build1.sif" "")
  data+=("7454d06767abea2c89cbbfbd5e17c961" "images/vcf-report-8.3.1.build1.sif" "")
  data+=("f96479aac5f6c2d6436d4fbac6e564d6" "images/vep-116.3.sif" "")
  data+=("ff8096ca3d00a59c8f345d54750e2c4d" "images/whatshap-2.8.build1.sif" "")
  data+=("bbb7bee9b968bcd3777061f9fd1ccbea" "nextflow-26.10.5-dist" "postprocess_nextflow")
  data+=("cfa476704db9a67c0f94d99eb67d0fd2" "resources/annotsv/v3.5.5/2406_phenotype.zip" "postprocess_annotsv_phenotype")
  data+=("a67ff13ccf5a346aee3cc27f35ffcffe" "resources/annotsv/v3.5.5/Annotations_Human_3.5.tar.gz" "postprocess_annotsv_annotations")
  data+=("296aedb05baca02176fe3c8767852d2d" "resources/annotsv/v3.5.5/jar/exomiser-rest-prioritiser-14.1.0.jar" "")
  data+=("94bac97fe4dbc4ad1a74bde3afb55603" "resources/gado/v1.0.4_HPO_v2024-08-13/HPO_2024_08_13_prediction_matrix.cols.txt.gz" "")
  data+=("4461c232ae1be508e7aa1fb44ade2292" "resources/gado/v1.0.4_HPO_v2024-08-13/HPO_2024_08_13_prediction_matrix.datg" "")
  data+=("6d50fbb9b2f74221265dede2aae13e71" "resources/gado/v1.0.4_HPO_v2024-08-13/HPO_2024_08_13_prediction_matrix.rows.txt.gz" "")
  data+=("31788f6a17183a5da370f338b808e325" "resources/gado/v1.0.4_HPO_v2024-08-13/hp.obo" "")
  data+=("da5e5e6fefd338d8224b1c075ae4aa74" "resources/gado/v1.0.4_HPO_v2024-08-13/genesProteinCoding.txt" "")
  data+=("74b9abc9a94c81fc27393e2f77ad498b" "resources/gado/v1.0.4_HPO_v2024-08-13/HPO_2024_08_13_prediction_info.txt.gz" "")
  data+=("55d49c8d95ffc9aee2ec584359c197d2" "resources/GRCh38/AlphScore_final_20230825_stripped_GRCh38.tsv.gz" "")
  data+=("c6178d80393254789ebf9c43df6f2d6f" "resources/GRCh38/AlphScore_final_20230825_stripped_GRCh38.tsv.gz.tbi" "")
  data+=("b12d66a565a43c32d2791972064040c3" "resources/GRCh38/apogee2_scores_20260414.tsv.gz" "")
  data+=("5a114663f9717cd86a6b315997197069" "resources/GRCh38/apogee2_scores_20260414.tsv.gz.tbi" "")
  data+=("dd90c1408de065ba7b27f8bd00a44d46" "resources/GRCh38/capice_model_v5.1.2_v6.ubj" "")
  data+=("c52254893af4d8393cf72c40d3ec07bf" "resources/GRCh38/clinvar_20260822_stripped.tsv.gz" "")
  data+=("2d6bfd500fac1170447356e41634ea78" "resources/GRCh38/clinvar_20260822_stripped.tsv.gz.tbi" "")
  data+=("c3197ab5a9e6a6e3429d611149b4dedd" "resources/GRCh38/default_exon_20250303.bed" "")
  data+=("f94e8888dd109d12512132a17793b4b9" "resources/GRCh38/default_gene_20250303.bed" "")
  data+=("8e842bfe9c1eeb0943a588ff5662b9aa" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.dict" "")
  data+=("5fddbc109c82980f9436aa5c21a57c61" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.fai" "")
  data+=("aab53048116f541b7aeef2da1c3e4ae7" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz" "postprocess_reference_genome")
  data+=("5fddbc109c82980f9436aa5c21a57c61" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.fai" "")
  data+=("db66bd01c2cb8a1ccb81c486239fa616" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.gzi" "")
  data+=("798b74ca2ff85b976ab51aab3f515c69" "resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.mmi" "")
  data+=("171b8ebe2020ed0d15f80681f8a342be" "resources/GRCh38/GCF_000001405.26_GRCh38_genomic_mapped.gff.gz" "")
  data+=("360f56abfe3e2ecb5e224733f948b3be" "resources/GRCh38/GRCh38_FATHMM-MKL_NC.tsv.gz" "")
  data+=("53827286f5827d2c2f0e4e6f02179ec2" "resources/GRCh38/GRCh38_FATHMM-MKL_NC.tsv.gz.tbi" "")
  data+=("b773b1eb1ef6e03ccdea70dcf736a17f" "resources/GRCh38/GRCh38_GREEN-DB.bed.gz" "")
  data+=("7837b9e42da9674e78d9874218f07f00" "resources/GRCh38/GRCh38_GREEN-DB.bed.gz.tbi" "")
  data+=("16b2f104b5131c643efffbf3a1501ee8" "resources/GRCh38/GRCh38_ncER_perc.bed.gz" "")
  data+=("498c22d840476a757be5f5b0e382f8d6" "resources/GRCh38/GRCh38_ncER_perc.bed.gz.tbi" "")
  data+=("a538173d85ea32638e05d36b602c8c32" "resources/GRCh38/GRCh38_PAR_20251126.bed" "")
  data+=("d6bf19522fdcf67b7ef871e1cde1970e" "resources/GRCh38/gnomad.total.v4.1.sites.stripped-v3.tsv.gz" "")
  data+=("9a0930823b0739a50816664fe9cfce0c" "resources/GRCh38/gnomad.total.v4.1.sites.stripped-v3.tsv.gz.tbi" "")
  data+=("d0ef2bd882ae44236897d743cb5528cf" "resources/GRCh38/gnomad.genomes.v3.1.sites.chrM.vcf.bgz" "")
  data+=("14f18719f5d86a00a00c475368913f8f" "resources/GRCh38/gnomad.genomes.v3.1.sites.chrM.vcf.bgz.tbi" "")
  data+=("43858006bdf98145b6fd239490bd0478" "resources/GRCh38/hg38.phyloP100way.bw" "")
  data+=("1c427de2e7f81caf73afbd50dd81cdf3" "resources/GRCh38/hmtvar_trna_scores.tsv.gz" "")
  data+=("7e64d9d639fd1501cbef8c24e1e866df" "resources/GRCh38/hmtvar_trna_scores.tsv.gz.tbi" "")
  data+=("86d75a85add01f940c4d5abc4bd596b9" "resources/GRCh38/human_GRCh38_no_alt_analysis_set.trf.bed" "")
  data+=("0b414afe1a7a75e3d2b8cd423a7bae88" "resources/GRCh38/mitotip_scores_20251118.tsv.gz" "")
  data+=("fa5c660d13b028ccdb896d1e51f47d7c" "resources/GRCh38/mitotip_scores_20251118.tsv.gz.tbi" "")
  data+=("2f8c8fcc75ea29f6798621d0446fe194" "resources/GRCh38/ReMM.v0.4.hg38.tsv.gz" "")
  data+=("c477b123abbe72c4aa66bf3abc18d9ab" "resources/GRCh38/ReMM.v0.4.hg38.tsv.gz.tbi" "")
  data+=("b01529a38ffe3f3b1a0e5feb5aa23232" "resources/GRCh38/spectre_GCA_000001405.15_GRCh38_no_alt_analysis_set.mdr" "")
  data+=("41689e1d397525ec79a511907f55b841" "resources/GRCh38/spectre_grch38_blacklist.bed" "")
  data+=("387e88471baa210ea71ad7db5457cc8c" "resources/GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz" "")
  data+=("8e9785fe994d0483250109e03344be38" "resources/GRCh38/spliceai_scores.masked.indel.hg38.vcf.gz.tbi" "")
  data+=("8e1bc03921ba0b818fe65eba314fa01b" "resources/GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz" "")
  data+=("a0f63b592b7b32fe36a9631793f341aa" "resources/GRCh38/spliceai_scores.masked.snv.hg38.vcf.gz.tbi" "")
  data+=("945ca0e357fa57249c8cb0d834cc6998" "resources/GRCh38/strs_20260319.stranger.json" "")
  data+=("a965a33b1c4e2333e9442de6b6c18d0c" "resources/GRCh38/strs_20260319.tsv" "")
  data+=("79c0b877cc166091bc27c0f53f65ce0e" "resources/GRCh38/strs_20260319.eh.json" "")
  data+=("644aa23c29f4a9507bae23ef65b936d7" "resources/GRCh38/uORF_5UTR_PUBLIC.txt" "")
  data+=("4195915e8316e4b8d0ce582db4a0e5f8" "resources/GRCh38/vkgl_consensus_20250701.tsv" "")
  data+=("d94140e762dfc6da23011718cccf2609" "resources/hpo_20240813.tsv" "")
  data+=("b62d33e85321a3104e58c129232e98df" "resources/hpo_20240813_phenotypic_abnormality.tsv" "")
  data+=("788d16796ba90b74a7c9b48d26905601" "resources/inheritance_20250411.tsv" "")
  data+=("88f31b0590a59e7996220c47b5ebe6c4" "resources/vep/cache/homo_sapiens_refseq_vep_116_GRCh38.tar.gz" "postprocess_vep")
  data+=("56042033325eb3714431ae81ccb3e6fd" "resources/vip-report-template-v8.6.0.html" "")


  for ((i = 0; i < ${#data[@]}; i += 3)); do
    if [[ ! "${vip_install_db["${data[i+1]}"]+_}" ]]; then
      install_file "${data[i+0]}" "${data[i+1]}" "${data[i+2]}"

       # update database
       echo -e "${data[i+1]}\t${VIP_VER}" >> "${vip_install_db_file}"
    fi
  done

  # remove old resources if prune is enabled
  if [ "${is_prune_enabled}" = "true" ]; then
      declare -A resources_map

      for ((i=0; i<${#data[@]}; i+=3)); do
          resources_map["${data[i+1]}"]="true"
      done

      mapfile -t files < <(find "${VIP_DIR_DATA}" -type f -printf "%P\n")
      for file in "${files[@]}"; do
          if [ "${file}" != "install.db" ]; then
              if [[ "${resources_map["${file}"]:-}" != "true" ]]; then
                  echo "File '${file}' is not a resource for the current VIP installation and will be removed."
                  rm "${VIP_DIR_DATA}/${file}"
                  escaped_file=$(echo "$file" | sed 's/\//\\\//g')
                  sed -i "/${escaped_file}/d" "${vip_install_db_file}"
              fi
          fi
      done
  fi
}

main() {
 local -r args=$(getopt -a -n install -o d:u:pv:h --long data_dir:,url:,prune,version:,help -- "$@")
  
  VIP_VER="${VIP_VER:-"dev"}"
  is_prune_enabled="false"
  
  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      ;;
    -u | --url)
      VIP_URL_DATA="$2"
      shift 2
      ;;
    -d | --data_dir)
      VIP_DIR_DATA="$2"
      shift 2
      ;;
    -v | --version)
      VIP_VER="$2"
      shift 2
      ;;
    -p | --prune)
      is_prune_enabled="true"
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      ;;
    esac
  done

  check_requirements
  install_files "${VIP_VER}" "${is_prune_enabled}"
}

main "${@}"
