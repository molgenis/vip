#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

source ${SCRIPT_DIR}/test_utils.sh

test_cram_nanopore () {
  download_test_resource "nanopore.cram"

  echo -e "params { vcf.filter.classes = \"B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"
  
  local args=()
  args+=("--workflow" "cram")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/cram_nanopore.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_bam () {
  echo -e "params { vcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "cram")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/bam.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

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
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_cram_multiproject () {
  echo -e "params { vcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"
  
  local args=()
  args+=("--workflow" "cram")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/cram_multiproject.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip1.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
  if [ ! "$(zcat "${OUTPUT_DIR}/vip2.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_cram_trio () {
  echo -e "params { vcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"
  ln -sf ${TEST_RESOURCES_DIR}/test1.cram ${TEST_RESOURCES_DIR}/test2.cram

  local args=()
  args+=("--workflow" "cram")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/cram_trio.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

run_tests () {
  before_all
  TEST_ID="cram_nanopore"
  before_each
  test_cram_nanopore
  after_each

  TEST_ID="bam"
  before_each
  test_bam
  after_each

  TEST_ID="cram"
  before_each
  test_cram
  after_each

  TEST_ID="cram_multiproject"
  before_each
  test_cram_multiproject
  after_each

  TEST_ID="cram_trio"
  before_each
  test_cram_trio
  after_each

  after_all
}

main () {
  run_tests
}

main "${@}"