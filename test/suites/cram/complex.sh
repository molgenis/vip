#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "$base_url/illumina_WES_GRCh38_chr20.cram" "5172c5531002d3a417da4744526caceb"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_solo_patient0.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_duo_patient1.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_duo_father1.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_duo_sibling_patient2.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_duo_sibling_mother2.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_duo_sibling_sibling2.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_trio_patient3.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_trio_father3.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_trio_mother3.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_trio_sibling_patient4.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_trio_sibling_father4.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_trio_sibling_mother4.cram"
ln -sf "${VIP_DIR_DATA}/test/resources/illumina_WES_GRCh38_chr20.cram" "${VIP_DIR_DATA}/test/resources/complex_trio_sibling_sibling4.cram"

args=()
args+=("--workflow" "cram")
args+=("--config" "${TEST_RESOURCES_DIR}/complex.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/complex.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0