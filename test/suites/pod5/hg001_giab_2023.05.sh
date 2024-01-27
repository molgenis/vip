#!/bin/bash
set -euo pipefail

# shellcheck disable=SC1091
source "${TEST_UTILS_DIR}/utils.sh"

  if ! aws s3 cp help &> /dev/null
  then
    echo "command 'cp' could not be found (possible solution: run 'ml awscli' before executing this script)"
    exit 1
  fi

aws s3 cp --region eu-west-1 --no-sign-request s3://ont-open-data/giab_2023.05/flowcells/hg001/20230505_1857_1B_PAO99309_94e07fab/pod5_pass/ ${TEST_RESOURCES_DIR}/downloads/ --recursive --exclude PAO99309_pass__94e07fab_c3641428_* --include PAO99309_pass__94e07fab_c3641428_9*

args=()
args+=("--workflow" "pod5")
args+=("--input" "${TEST_RESOURCES_DIR}/hg001_giab_2023_05.tsv")
args+=("--config" "${TEST_RESOURCES_DIR}/hg001_giab_2023_05.cfg")
args+=("--output" "${OUTPUT_DIR}")
args+=("--resume")

vip "${args[@]}" 1> /dev/null

compare expected to actual output and store result
if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
  result="0"
else
  result="1"
fi
echo -n "${result}" > "${OUTPUT_DIR}/.exitcode"

# always exit with success error code
exit 0