#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source ${SCRIPT_DIR}/test_utils.sh

test_bam () {
  local args=()
  args+=("--workflow" "cram")
  args+=("--input" "${TEST_RESOURCES_DIR}/bam.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--profile" "slurm")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_cram () {
  local args=()
  args+=("--workflow" "cram")
  args+=("--input" "${TEST_RESOURCES_DIR}/cram.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--profile" "slurm")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

run_tests () {
  before_all

  TEST_ID="bam"
  before_each
  test_bam
  after_each

  TEST_ID="cram"
  before_each
  test_cram
  after_each

  after_all
}

main () {
  run_tests
}

main "${@}"