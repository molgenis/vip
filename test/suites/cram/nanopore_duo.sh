#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "$base_url/nanopore.cram" "e66e9d364766e0d45f03bdc25d42cf24"
ln -sf "${VIP_DIR_DATA}/test/resources/nanopore.cram" "${VIP_DIR_DATA}/test/resources/nanopore_copy.cram"

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