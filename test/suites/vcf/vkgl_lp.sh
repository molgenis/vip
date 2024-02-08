#!/bin/bash
set -euo pipefail

args=()
args+=("--workflow" "vcf")
args+=("--input" "${TEST_RESOURCES_DIR}/vkgl_lp.tsv")
args+=("--config" "${TEST_RESOURCES_DIR}/vkgl_lp.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

vip "${args[@]}" 1> /dev/null

# compare expected to actual output and store result
if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -lt 2360 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0