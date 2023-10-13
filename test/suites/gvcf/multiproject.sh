#!/bin/bash
set -euo pipefail

args=()
args+=("--workflow" "gvcf")
args+=("--input" "${TEST_RESOURCES_DIR}/multiproject.tsv")
args+=("--config" "${TEST_RESOURCES_DIR}/multiproject.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

vip "${args[@]}" 1> /dev/null

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip0.vcf.gz" | grep -vc "^#")" -eq 1 ] && [ "$(zcat "${OUTPUT_DIR}/vip1.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0