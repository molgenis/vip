#!/bin/bash
set -euo pipefail

args=()
args+=("--workflow" "vcf")
args+=("--input" "${TEST_RESOURCES_DIR}/vkgl_lb.tsv")
args+=("--config" "${TEST_RESOURCES_DIR}/vkgl_lb.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

vip.sh "${args[@]}" 1> /dev/null

# compare expected to actual output and store result
# +50 because of non-deterministic behavior, see https://github.com/molgenis/vip/issues/604
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -le $((4528 + 50)) ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0