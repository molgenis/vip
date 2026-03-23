#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

# code to generate new style (adpative sampling specification >= 0.1) adaptive_sampling.csv
# zgrep "^@m54238" m54238_180628_014238_s0_10000.Q20.part_001.fastq.gz | cut -c2- | awk 'BEGIN { FS=","; OFS="," } NR==1 { printf "read_id,action,action_response\n" } NR>1 { printf "%s,%s,%s\n", $1, (NR%2==0 ? "sequence" : "unblock"), (NR%3==0 ? "SUCCESS" : NR%2==0 ? "FAILED_READ_FINISHED" : "FAILED_READ_TOO_LONG") }' >> m54238_180628_014238_s0_10000.Q20.adaptive_sampling_adaptive01_v2.csv
# zgrep "^@m54238" m54238_180628_014238_s0_10000.Q20.part_002.fastq.gz | cut -c2- | awk 'BEGIN { FS=","; OFS="," } NR>1 { printf "%s,%s,%s\n", $1, (NR%2==0 ? "sequence" : "unblock"), (NR%3==0 ? "SUCCESS" : NR%2==0 ? "FAILED_READ_FINISHED" : "FAILED_READ_TOO_LONG") }' >> m54238_180628_014238_s0_10000.Q20.adaptive_sampling_adaptive01_v2.csv

download "${base_url}/m54238_180628_014238_s0_10000.Q20.part_001.fastq.gz" "c1de90bc77fb413347e6a6aaf2e4660d"
download "${base_url}/m54238_180628_014238_s0_10000.Q20.part_002.fastq.gz" "db37d492beea41c505ce4ab5fe8df8ec"
download "${base_url}/m54238_180628_014238_s0_10000.Q20.adaptive_sampling_new_v2.csv" "60a94684c32094dc2c763f5e871c6062"

args=()
args+=("--workflow" "fastq")
args+=("--config" "${TEST_RESOURCES_DIR}/nanopore_adaptive_sampling_new.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

runVip "${args}" "${TEST_RESOURCES_DIR}/nanopore_adaptive_sampling_new.tsv"

# compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  # check if intermediate cram was published
  if [ -f "${OUTPUT_DIR}/intermediates/vip_fam0_HG002.cram" ]; then
    result="0"
  else
    result="1"
  fi
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0