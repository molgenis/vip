#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download_test_resource "nanopore.cram" "${TEST_RESOURCES_DIR}/downloads"
  
args=()
args+=("--workflow" "cram")
args+=("--input" "${TEST_RESOURCES_DIR}/nanopore.tsv")
args+=("--config" "${TEST_RESOURCES_DIR}/nanopore.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

vip "${args[@]}" 1> /dev/null

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0