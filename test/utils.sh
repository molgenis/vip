#!/bin/bash
set -euo pipefail

base_url=https://download.molgeniscloud.org/downloads/vip/test/resources/

# arguments:
#   $1  url
#   $2  md5 checksum
#   $3  output directory
download() {
  local -r url="${1}"
  local -r md5="${2}"
  local -r output_dir="${3}"

  local -r filename="${url##*/}"
  local -r output="${output_dir}/${filename}"

  if [ ! -f "${output}" ]; then
    mkdir -p "${output_dir}"
    if ! wget --quiet --continue "${url}" --output-document "${output}"; then
      echo -e "an error occurred downloading ${url}"
        # wget always writes an (empty) output file regardless of errors
        rm -f "${output}"
        exit 1
    fi
  fi

  if ! echo "${md5}"  "${output_dir}/${filename}" | md5sum --check --quiet --status --strict; then
    echo -e "checksum check failed for '${output_dir}/${filename}'"
    exit 1
  fi
}
