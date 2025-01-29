#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

base_url="https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data"

declare -A files=()
files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7035_TAAGGCGA_L001_R1_001_trimmed.fastq.gz"]="9195dceb8b97564915b9a67c8b8a5271"
files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7035_TAAGGCGA_L001_R2_001_trimmed.fastq.gz"]="c32ea5571d48e339dc4a21b762e89cb6"
files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7035_TAAGGCGA_L002_R1_001_trimmed.fastq.gz"]="5a08668e4ccf75f3ad24a7012d56d821"
files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7035_TAAGGCGA_L002_R2_001_trimmed.fastq.gz"]="3ff1caf9a2b9824f1f855f8be7ceb042"
files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7086_CGTACTAG_L001_R1_001_trimmed.fastq.gz"]="5e36556544aabfc66c1ce7fb28d1d5b9"
files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7086_CGTACTAG_L001_R2_001_trimmed.fastq.gz"]="38bde678b2dd73ec8a2b07d48e1421f8"
files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7086_CGTACTAG_L002_R1_001_trimmed.fastq.gz"]="d3519eb5b12d2248afb65431908412a1"
files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7086_CGTACTAG_L002_R2_001_trimmed.fastq.gz"]="efb711af9498c2d11c406f9bd06b0c0a"

for i in "${!files[@]}"; do
  download "${i}" "${files[$i]}" "${TEST_RESOURCES_DIR}/downloads"
done

args=()
args+=("--workflow" "fastq")
args+=("--input" "${TEST_RESOURCES_DIR}/NA12878_illumina_hiseq_exome.tsv")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

vip.sh "${args[@]}" 1> /dev/null

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0