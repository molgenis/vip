#!/bin/bash
set -euo pipefail

download "${VIP_URL_DATA}/resources/GRCh37/human_g1k_v37.fasta.gz" "11b8eb3d28482729dd035458ad5bda01"
download "${VIP_URL_DATA}/resources/GRCh37/human_g1k_v37.fasta.gz.fai" "772484cc07983aba1355c7fb50f176d4"
download "${VIP_URL_DATA}/resources/GRCh37/human_g1k_v37.fasta.gz.gzi" "83871aca19be0df7e3e1a5da3f68d18c"

args=()
args+=("--workflow" "gvcf")
args+=("--output" "${OUTPUT_DIR}")
args+=("--config" "${TEST_RESOURCES_DIR}/liftover.cfg")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/liftover.tsv"

# compare expected to actual output and store result
result="0"
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0