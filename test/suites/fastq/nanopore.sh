#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download_test_resource "m54238_180628_014238_s0_10000.Q20.part_001.fastq.gz" "${TEST_RESOURCES_DIR}/downloads"
download_test_resource "m54238_180628_014238_s0_10000.Q20.part_002.fastq.gz" "${TEST_RESOURCES_DIR}/downloads"

args=()
args+=("--workflow" "fastq")
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