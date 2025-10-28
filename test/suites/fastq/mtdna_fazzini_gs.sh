#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

download "${base_url}/H1-Herk_S171_R1_001.fastq.gz" "215bc21d0a45db49f8cf92e1515ef1de"
download "${base_url}/H1-Herk_S171_R2_001.fastq.gz" "f6620299c2389c428179a7ebf71fb59e"
download "${base_url}/M1-PCR-Herk_S111_R1_001.fastq.gz" "de10ced51541a40e1ea414a443b2a1af"
download "${base_url}/M1-PCR-Herk_S111_R2_001.fastq.gz" "e44879fb0e87974302194a89838ca57a"
download "${base_url}/M2-PCR-Herk_S121_R1_001.fastq.gz" "73975104955b5cf1ecdcb2c4075d6862"
download "${base_url}/M2-PCR-Herk_S121_R2_001.fastq.gz" "4d2aa6ae0d3242590149dd6485d59e1d"
download "${base_url}/U5-Herk_S161_R1_001.fastq.gz" "0185f8095aef51f7a600343db3c86412"
download "${base_url}/U5-Herk_S161_R2_001.fastq.gz" "13a47f314036c68034d561a6a9debc4f"


args=()
args+=("--workflow" "fastq")
args+=("--config" "${TEST_RESOURCES_DIR}/mtdna_fazzini_gs.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/mtdna_fazzini_gs.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -ge 35 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0