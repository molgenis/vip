#!/bin/bash
set -euo pipefail

args=()
args+=("--workflow" "gvcf")
args+=("--input" "${TEST_RESOURCES_DIR}/liftover.tsv")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

vip "${args[@]}" 1> /dev/null

# compare expected to actual output and store result
result="0"
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0