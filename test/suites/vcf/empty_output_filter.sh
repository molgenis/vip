#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

args=()
args+=("--workflow" "vcf")
args+=("--config" "${TEST_RESOURCES_DIR}/empty_output_filter.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/empty_output_filter.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0