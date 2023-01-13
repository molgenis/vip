#!/bin/bash

source ./test_utils.sh

test_gvcf () {
  echo -e "params { vcf.filter.classes = \"LQ,B,LB,VUS,LP,P\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "vcf")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/gvcf.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--profile" "local")
  args+=("--assembly" "GRCh38")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
    return 1
  fi
}

main () {
  run_tests
}