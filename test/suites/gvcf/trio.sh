#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "${base_url}/HG002.illumina.wes.chr20.g.vcf.gz" "1bf1215247d3480cdcf6d918b530a4ec"
download "${base_url}/HG003.illumina.wes.chr20.g.vcf.gz" "34343985ddf6c0903c4096cbd96b6a1f"
download "${base_url}/HG004.illumina.wes.chr20.g.vcf.gz" "cca6f2fa92597c99d100933a9f07874f"
ln -sf "${VIP_DIR_DATA}/test/resources/HG002.illumina.wes.chr20.g.vcf.gz" "${VIP_DIR_DATA}/test/resources/trio_proband.g.vcf.gz"
ln -sf "${VIP_DIR_DATA}/test/resources/HG003.illumina.wes.chr20.g.vcf.gz" "${VIP_DIR_DATA}/test/resources/trio_father.g.vcf.gz"
ln -sf "${VIP_DIR_DATA}/test/resources/HG004.illumina.wes.chr20.g.vcf.gz" "${VIP_DIR_DATA}/test/resources/trio_mother.g.vcf.gz"

download "${base_url}/illumina_WES_GRCh38_chr20.cram" "5172c5531002d3a417da4744526caceb"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/trio_proband.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/trio_father.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/trio_mother.cram"

args=()
args+=("--workflow" "gvcf")
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