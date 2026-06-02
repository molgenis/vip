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

runHappy() {
  local happy_args=()
  happy_args+=("hap.py")
  happy_args+=("${1}")
  happy_args+=("${2}")
  happy_args+=("-o" "${OUTPUT_DIR}/happy_out/test")
  if [[ -v 3 ]]; then
    happy_args+=("-r" "${3}")
  else
    happy_args+=("-r" "${VIP_DIR_DATA}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna")
  fi
  
  mkdir -p "${OUTPUT_DIR}/happy_out"

  vip_images_dir="${VIP_DIR_DATA}/images"
  
  apptainer exec "${vip_images_dir}/happy-0.3.15.sif" "${happy_args[@]}"
}

runSompy() {
  local sompy_args=()
  sompy_args+=("som.py")
  sompy_args+=("${1}")
  sompy_args+=("${2}")
  sompy_args+=("-o" "${OUTPUT_DIR}/sompy_out/test")
  if [[ -v 3 ]]; then
    sompy_args+=("-r" "${3}")
  else
    sompy_args+=("-r" "${VIP_DIR_DATA}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna")
  fi

  mkdir -p "${OUTPUT_DIR}/sompy_out"

  vip_images_dir="${VIP_DIR_DATA}/images"

  apptainer exec "${vip_images_dir}/happy-0.3.15.sif" "${sompy_args[@]}"
}

sompyF1Score() {
  f1_score=$(printf "%0.2f" "$(echo "2 * ((${1} * ${2}) / (${1} + ${2}))" | bc -l)")
  echo "${f1_score}"
}