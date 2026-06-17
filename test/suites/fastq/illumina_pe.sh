#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "${base_url}/hg002_chr10_r1.fastq.gz" "9251776bb44794849f0e55a85079aa43"
download "${base_url}/hg002_chr10_r2.fastq.gz" "cbf8e8df37668dc8c84fb736b6bfe748"
download "${base_url}/hg004_chr10_r1.fastq.gz" "7d0532454077d877305b7649971ce528"
download "${base_url}/hg004_chr10_r2.fastq.gz" "4c8c15f7b99d97ea891e1a8834ab8e39"


args=()
args+=("--workflow" "fastq")
args+=("--config" "${TEST_RESOURCES_DIR}/illumina_pe.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/illumina_pe.tsv"

# compare expected to actual output and store result
if [[ $(zgrep -c "chr10	68142950	chr10_68142950_G_A	G	A" "${OUTPUT_DIR}/vip.vcf.gz") -eq "1" ]]; then
    result="0"
else
    result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0