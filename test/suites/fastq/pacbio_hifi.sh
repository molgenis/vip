#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "{$base_url}/m54238_180628_014238_s0_10000.Q20.fastq.gz" "749786503c0ae5c9e325f025067ed4f2"

args=()
args+=("--workflow" "fastq")
args+=("--config" "${TEST_RESOURCES_DIR}/pacbio_hifi.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/pacbio_hifi.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0