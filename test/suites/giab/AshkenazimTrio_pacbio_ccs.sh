#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

base_url="ftp://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data"

declare -A files=()
files["${base_url}/AshkenazimTrio/HG002_NA24385_son/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG002.SequelII.merged_15kb_20kb.pbmm2.GRCh38.haplotag.10x.bam"]="d303b337a2e9ffedef0f2ad894078ac6"
files["${base_url}/AshkenazimTrio/HG003_NA24149_father/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG003.SequelII.merged_15kb_20kb.pbmm2.GRCh38.haplotag.10x.bam"]="5d0ff146b26d403dac982a88028bb6bd"
files["${base_url}/AshkenazimTrio/HG004_NA24143_mother/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG004.SequelII.merged_15kb_20kb.pbmm2.GRCh38.haplotag.10x.bam"]="fd6d3806997c74eb539f2b7f47dab2ab"

for i in "${!files[@]}"; do
  download "${i}" "${files[$i]}" "${TEST_RESOURCES_DIR}/downloads"
done

args=()
args+=("--workflow" "cram")
args+=("--input" "${TEST_RESOURCES_DIR}/giab_AshkenazimTrio_pacbio_ccs.tsv")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

vip "${args[@]}" 1> /dev/null

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0