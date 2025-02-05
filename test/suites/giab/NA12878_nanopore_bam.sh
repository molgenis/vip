#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

base_url="https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data"

declare -A files=()
files["${base_url}/NA12878/Ultralong_OxfordNanopore/NA12878-minion-ul_GRCh38.bam"]="f4a7702cf82ea2586396e485567fa6f8"
files["${base_url}/NA12878/Ultralong_OxfordNanopore/NA12878-minion-ul_GRCh38.bam.bai"]="0654a1ebef25da1753c830b007854a58"

for i in "${!files[@]}"; do
  download "${i}" "${files[$i]}"
done

args=()
args+=("--workflow" "cram")
args+=("--config" "${TEST_RESOURCES_DIR}/NA12878_nanopore_bam.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/NA12878_nanopore_bam.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0