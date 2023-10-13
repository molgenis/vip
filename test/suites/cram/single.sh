#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download_test_resource "chr22.cram" "${TEST_RESOURCES_DIR}/downloads"
ln -sf "${TEST_RESOURCES_DIR}/downloads/chr22.cram" "${TEST_RESOURCES_DIR}/downloads/single.cram"

args=()
args+=("--workflow" "cram")
args+=("--input" "${TEST_RESOURCES_DIR}/single.tsv")
args+=("--config" "${TEST_RESOURCES_DIR}/single.cfg")
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