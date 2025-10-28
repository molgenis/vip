#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "${base_url}/illumina_WES_GRCh38_chr20.cram" "5172c5531002d3a417da4744526caceb"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/single.cram"

args=()
args+=("--workflow" "cram")
args+=("--config" "${TEST_RESOURCES_DIR}/single.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/single.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0