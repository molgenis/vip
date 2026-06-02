#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

args=()
args+=("--workflow" "vcf")
args+=("--config" "${TEST_RESOURCES_DIR}/jvar_plp.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/jvar_plp.tsv"

runSompy "${TEST_RESOURCES_DIR}/jvar_plp.vcf" "${OUTPUT_DIR}/vip.vcf.gz"

# collect the recall and precision and f1 score value
total_recall=$(grep '5,records' "${OUTPUT_DIR}/sompy_out/test.stats.csv" | cut -d ',' -f 10)
total_precision=$(grep '5,records' "${OUTPUT_DIR}/sompy_out/test.stats.csv" | cut -d ',' -f 14)
f1_total=$(sompyF1Score "${total_precision}" "${total_recall}")

# compare expected to actual output and store result
test_threshold="0.93"
if (( $(echo "${f1_total} == ${test_threshold}" | bc -l) )); then
    result="0"
else
    echo "Expected f1 score is ${test_threshold} ; but actual test f1 score was ${f1_total}"
    result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0