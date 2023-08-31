#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

source ${SCRIPT_DIR}/test_utils.sh

test_gvcf () {
  echo -e "params { gvcf.merge_preset = \"DeepVariant\"\nvcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "gvcf")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/gvcf.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
    return 1
  fi
}

test_gvcf_multiproject () {
  echo -e "params { gvcf.merge_preset = \"DeepVariant\"\nvcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "gvcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/gvcf_multiproject.tsv")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip0.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
    return 1
  fi
  if [ ! "$(zcat "${OUTPUT_DIR}/vip1.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
    return 1
  fi
}

run_tests () {
  before_all

  TEST_ID="gvcf"
  before_each
  test_gvcf
  after_each

  TEST_ID="gvcf_multiproject"
  before_each
  test_gvcf_multiproject
  after_each

  after_all
}

main () {
  run_tests
}

main "${@}"
