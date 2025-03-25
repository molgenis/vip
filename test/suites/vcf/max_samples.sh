#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

args=()
args+=("--workflow" "vcf")
args+=("--config" "${TEST_RESOURCES_DIR}/max_samples.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/max_samples.tsv"

# compare expected to actual number of samples
if [ "$(zgrep "^#CHROM" ${OUTPUT_DIR}/vip.vcf.gz | awk '{print NF-9}')" -eq 10 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0