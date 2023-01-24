#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")
source ${SCRIPT_DIR}/test_utils.sh

test_gvcf () {
  echo -e "params { vcf.gvcf_merge_preset = \"DeepVariant\"\nvcf.filter.classes = \"LQ,B,LB,VUS,LP,P\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "vcf")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/gvcf.tsv")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
    return 1
  fi
}

test_empty_input () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/empty_input.tsv")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 0 ]; then
    return 1
  fi
}

test_empty_output_filter () {
  echo -e "params { vcf.filter.classes = \"B\" }" > "${OUTPUT_DIR}/custom.cfg"
  
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/empty_output_filter.tsv")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 0 ]; then
    return 1
  fi
}

test_empty_output_filter_samples () {
  echo -e "params { vcf.filter_samples.classes = \"R\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/empty_output_filter_samples.tsv")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 0 ]; then
    return 1
  fi
}

test_multiproject () {
  echo -e "params { vcf.gvcf_merge_preset = \"DeepVariant\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/multiproject.tsv")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--output" "${OUTPUT_DIR}")

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

test_corner_cases () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/corner_cases.tsv")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi
}

test_snv_proband () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv_proband.tsv")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 2 ]; then
    return 1
  fi
}

test_snv_proband_trio () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv_proband_trio.tsv")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 3 ]; then
    return 1
  fi
}

test_snv_proband_trio_sample_filtering () {
  echo -e "params { vcf.filter_samples.classes = \"K\" }" > "${OUTPUT_DIR}/custom.cfg"
  
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv_proband_trio.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 2 ] > /dev/null 2>&1; then
    return 1
  fi
}

test_snv_proband_trio_b38 () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv_proband_trio_b38.tsv")
  args+=("--output" "${OUTPUT_DIR}")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 2 ]; then
    return 1
  fi
}

test_lp () {
  echo -e "params { vcf.annotate.GRCh37.vep_plugin_vkgl = \"${TEST_RESOURCES_DIR}/vkgl_public_consensus_empty.tsv\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/lp.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -lt 2439 ]; then
    return 1
  fi
}

test_lp_b38 () {
  echo -e "params { vcf.annotate.GRCh38.vep_plugin_vkgl = \"${TEST_RESOURCES_DIR}/vkgl_public_consensus_empty.tsv\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/lp_b38.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -lt 2440 ]; then
    return 1
  fi
}

test_lb () {
  echo -e "params { vcf.annotate.GRCh37.vep_plugin_vkgl = \"${TEST_RESOURCES_DIR}/vkgl_public_consensus_empty.tsv\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/lb.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 1150 ]; then
    return 1
  fi
}

test_lb_b38 () {
  echo -e "params { vcf.annotate.GRCh38.vep_plugin_vkgl = \"${TEST_RESOURCES_DIR}/vkgl_public_consensus_empty.tsv\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/lb_b38.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 1233 ]; then
    return 1
  fi
}

run_tests () {
  before_all

  TEST_ID="gvcf"
  before_each
  test_gvcf
  after_each

  TEST_ID="test_empty_input"
  before_each
  test_empty_input
  after_each

  TEST_ID="test_empty_output_filter"
  before_each
  test_empty_output_filter
  after_each

  TEST_ID="test_empty_output_filter_samples"
  before_each
  test_empty_output_filter_samples
  after_each

  TEST_ID="test_multiproject"
  before_each
  test_multiproject
  after_each

  TEST_ID="test_corner_cases"
  before_each
  test_corner_cases
  after_each

  TEST_ID="test_snv_proband"
  before_each
  test_snv_proband
  after_each

  TEST_ID="test_snv_proband_trio"
  before_each
  test_snv_proband_trio
  after_each

  TEST_ID="test_snv_proband_trio_sample_filtering"
  before_each
  test_snv_proband_trio_sample_filtering
  after_each

  TEST_ID="test_snv_proband_trio_b38"
  before_each
  test_snv_proband_trio_b38
  after_each

  TEST_ID="test_lp"
  before_each
  test_lp
  after_each

  TEST_ID="test_lp_b38"
  before_each
  test_lp_b38
  after_each

  TEST_ID="test_lb"
  before_each
  test_lb
  after_each

  TEST_ID="test_lb_b38"
  before_each
  test_lb_b38
  after_each

  after_all
}

main () {
  run_tests
}

main "${@}"
