#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "$base_url/HG003_chr10_20.cram" "7fcbf7ff6cf42a7f7d529c8c582cb525"
download "$base_url/HG002_chr10_20.cram" "53eae7c6c791b66c258c5fc062082293"

args=()
args+=("--workflow" "cram")
args+=("--config" "${TEST_RESOURCES_DIR}/nanopore_duo.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/nanopore_duo.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0