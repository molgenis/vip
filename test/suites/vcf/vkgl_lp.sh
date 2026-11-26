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

read -r precision recall f1_total <<< "$(runVcfCompare "${TEST_RESOURCES_DIR}/vkgl_lp_202507.bcf" "${OUTPUT_DIR}/vip.vcf.gz")"

# compare expected to actual output and store result
test_threshold="0.98"
if (( $(echo "${f1_total} >= ${test_threshold}" | bc -l) )); then
    echo "Test f1 score was ${f1_total}"
    result="0"
else
    echo "Expected f1 score is ${test_threshold} ; but actual test f1 score was ${f1_total}"
    result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0