#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source ${SCRIPT_DIR}/test_utils.sh

test_bam () {
  echo -e "params { vcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "cram")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/bam.tsv")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_cram () {
  echo -e "params { vcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"
  
  local args=()
  args+=("--workflow" "cram")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/cram.tsv")
  args+=("--output" "${OUTPUT_DIR}")

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