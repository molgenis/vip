#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "$base_url/m54238_180628_014238_s0_10000.Q20.part_001.fastq.gz" "c1de90bc77fb413347e6a6aaf2e4660d"
download "$base_url/m54238_180628_014238_s0_10000.Q20.part_002.fastq.gz" "db37d492beea41c505ce4ab5fe8df8ec"

args=()
args+=("--workflow" "fastq")
args+=("--config" "${TEST_RESOURCES_DIR}/nanopore.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/nanopore.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0