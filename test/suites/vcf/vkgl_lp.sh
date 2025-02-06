#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

args=()
args+=("--workflow" "vcf")
args+=("--config" "${TEST_RESOURCES_DIR}/vkgl_lp.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/vkgl_lp.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -ge 26732 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0