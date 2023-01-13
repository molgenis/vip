#!/bin/bash

source ./test_utils.sh

test_gvcf () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/gvcf.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--profile" "slurm")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/NA12878.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

run_tests () {
  before_all

  TEST_ID="gvcf"
  before_each
  test_gvcf
  after_each

  after_all
}

main () {
  run_tests
}