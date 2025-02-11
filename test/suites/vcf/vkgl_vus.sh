#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

args=()
args+=("--workflow" "vcf")
args+=("--config" "${TEST_RESOURCES_DIR}/vkgl_vus.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/vkgl_vus.tsv"

result="0"
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0