#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "$base_url/illumina_WES_GRCh38_chr20.bam" "a50b0cbac22d19197b868e4d81826e38"
download "$base_url/illumina_WES_GRCh38_chr20.cram" "5172c5531002d3a417da4744526caceb"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.bam" "${VIP_DIR_DATA}/test/resources/trio_patient.bam"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/trio_father.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/trio_mother.cram"

args=()
args+=("--workflow" "cram")
args+=("--config" "${TEST_RESOURCES_DIR}/trio.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/trio.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0