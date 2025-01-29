#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

base_url="https://downloads.molgeniscloud.org/downloads/vip/test/resources"

declare -A files=()
files["${base_url}/HG002.illumina.wes.R1.fastq.gz"]="ac91e658cd6c73f679d7149b86f17ef2"
files["${base_url}/HG002.illumina.wes.R2.fastq.gz"]="2f1617999c1cd288258eb7a99616727e"
files["${base_url}/HG003.illumina.wes.R1.fastq.gz"]="a6345fc4eaa6e12e617ac96a65726daa"
files["${base_url}/HG003.illumina.wes.R2.fastq.gz"]="e3339c639add374214be508db186b8fd"
files["${base_url}/HG004.illumina.wes.R1.fastq.gz"]="ad3f8561e7c8c5b730510c35f550791a"
files["${base_url}/HG004.illumina.wes.R2.fastq.gz"]="6060c7cfe25a25209e4a3513ab7da60f"

for i in "${!files[@]}"; do
  download "${i}" "${files[$i]}" "${TEST_RESOURCES_DIR}/downloads"
done

args=()
args+=("--workflow" "fastq")
args+=("--input" "${TEST_RESOURCES_DIR}/AshkenazimTrio_illumina_wes.tsv")
args+=("--config" "${TEST_RESOURCES_DIR}/AshkenazimTrio_illumina_wes.cfg")
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