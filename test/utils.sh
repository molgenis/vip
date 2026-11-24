#!/bin/bash
set -euo pipefail

VIP_URL_DATA="${VIP_URL_DATA:-"https://download.molgeniscloud.org/downloads/vip"}"
test_dir="/test/resources/"
base_url="${VIP_URL_DATA}${test_dir}"

# arguments:
#   $1  path relative to file
#   $2  md5 checksum
download() {
  local -r file_url="${1}"
  local -r md5="${2}"
  local -r file_basename="$(basename "${file_url}")"
  local -r file="${VIP_DIR_DATA}${test_dir}${file_basename}"

  mkdir -p ${VIP_DIR_DATA}${test_dir}
  local -r vip_install_test_db_file="${VIP_DIR_DATA}/test/install.db"
  declare -A vip_install_db
  if [[ ! -f "${vip_install_test_db_file}" ]]; then
    # create new database
    touch "${vip_install_test_db_file}"
  fi

  local -r file_db_entry="$(realpath --relative-to="$(dirname "${vip_install_test_db_file}")" "${file}")"
  if ! grep --fixed-strings --line-regexp --quiet "${file_db_entry}" "${vip_install_test_db_file}"; then
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
    echo -e "${file_db_entry}" >> "${vip_install_test_db_file}"
  fi
}

runVip() {
  #replace environment variables with actual values
  local -r processed_input=${OUTPUT_DIR}/samplesheet.tsv
  args=$1
  envsubst < $2 > "${processed_input}"
  args+=("--input" "${processed_input}")

  vip.sh "${args[@]}" 1> /dev/null
}

# Arguments:
#   $1  path to VCF gold standard set (vcf, vcf.gz or bcf)
#   $2  path to test VCF results (vcf, vcf.gz or bcf)
#   $3  filter query to PASS variants only (true/false, default false)
runVcfCompare() {
  local truth="$1"
  local query="$2"
  local pass_only="${3:-false}"

  local out="${OUTPUT_DIR}/isec_out"
  local vip_images_dir="${VIP_DIR_DATA}/images"
  local bcftools_sif="${vip_images_dir}/bcftools-1.25.sif"

  rm -rf "${out}"
  mkdir -p "${out}" || return 1

  CMD_BCFTOOLS() {
    apptainer exec "${bcftools_sif}" bcftools "$@"
  }

  CMD_BCFTOOLS view "${truth}" -Oz \
    -o "${out}/truth.vcf.gz" || return 1

  CMD_BCFTOOLS index -f "${out}/truth.vcf.gz" || return 1
  local view_args=()
  [[ "${pass_only}" == "true" ]] && view_args+=(--apply-filters PASS)

  CMD_BCFTOOLS view "${view_args[@]}" "${query}" -Oz \
    -o "${out}/query.vcf.gz" || return 1
  CMD_BCFTOOLS index -f "${out}/query.vcf.gz" || return 1
  CMD_BCFTOOLS isec -c none -Ov -p "${out}/isec" \
    "${out}/truth.vcf.gz" \
    "${out}/query.vcf.gz" || return 1

  local fn fp tp

  fn=$(grep -vc '^#' "${out}/isec/0000.vcf" || 0)
  fp=$(grep -vc '^#' "${out}/isec/0001.vcf" || 0)
  tp=$(grep -vc '^#' "${out}/isec/0002.vcf" || 0)

  unset -f CMD_BCFTOOLS

  # Calculate precision, recall and F1
  awk -v tp="${tp}" -v fp="${fp}" -v fn="${fn}" 'BEGIN {
    p = (tp+fp) ? tp/(tp+fp) : 0
    r = (tp+fn) ? tp/(tp+fn) : 0
    f = (p+r) ? 2*p*r/(p+r) : 0

    printf "%.2f %.2f %.2f\n", p, r, f
  }'
}