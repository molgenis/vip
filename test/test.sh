#!/bin/bash
SCRIPT_DIR=$(dirname "$(realpath "$0")")

trap abort SIGINT
abort() {
   echo "execution aborted by user"
   exit 1
}

CMD_VIP="$(realpath "${SCRIPT_DIR}/../vip")"
NXF_VERSION="22.10.2"
CMD_NEXTFLOW="$(realpath "${SCRIPT_DIR}/../nextflow")"

TEST_DIR="${SCRIPT_DIR}"
TEST_RESOURCES_DIR="${TEST_DIR}/resources"
RESOURCES_DIR="$(realpath "${SCRIPT_DIR}/../resources/")"
TEST_OUTPUT_DIR="${TEST_DIR}/output"

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m"

declare -i PASSED=0
declare -i FAILED=0

before_all () {
  echo -e "executing tests ..."

  rm -rf "${TEST_OUTPUT_DIR}"
  mkdir "${TEST_OUTPUT_DIR}"

  # nextflow creates a .nextflow folder in the current directory
  # make sure that this folder is always created in the output directory
  cd "${TEST_DIR}" || exit

  export NXF_OFFLINE=true
  export NXF_HOME="${TEST_DIR}/.nextflow"

   if [ ${FAILED} -gt 0 ]; then
     echo -e "${RED}FAILED${NC} ${TEST_ID}"
   fi
}

before_each () {
  OUTPUT_DIR="${TEST_OUTPUT_DIR}/${TEST_ID}"
  OUTPUT_LOG="${TEST_OUTPUT_DIR}/${TEST_ID}/.nxf.log"
  mkdir -p "${OUTPUT_DIR}"

  export NXF_WORK="${OUTPUT_DIR}/.nxf_work"
  export NXF_TEMP="${OUTPUT_DIR}/.nxf_temp"
}

after_each () {
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}PASSED${NC} ${TEST_ID}"
    PASSED=${PASSED}+1
  else
    echo -e "${RED}FAILED${NC} ${TEST_ID}, see ${OUTPUT_LOG}"
    FAILED=${FAILED}+1
  fi
}

after_all () {
  if [ ${FAILED} -gt 0 ]; then
    echo -e "${FAILED} test(s) failed"
    return 1
  else
    echo -e "all tests passed successfully"
  fi
}

test_empty_input () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/empty_input.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--profile" "local")

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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh37")

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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh37")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -eq 0 ]; then
    return 1
  fi
}

test_multiproject () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/multiproject.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--profile" "local")

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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh37")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi
}

test_snv_proband () {
  local args=()
  args+=("--workflow" "vcf")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv_proband.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--profile" "local")
  args+=("--assembly" "GRCh37")

  if ! "${CMD_VIP}" "${args[@]}"; then
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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh37")

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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh37")

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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh38")

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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh37")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -lt 2452 ]; then
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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh38")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -lt 2450 ]; then
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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh37")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 1346 ]; then
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
  args+=("--profile" "local")
  args+=("--assembly" "GRCh38")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 1272 ]; then
    return 1
  fi
}

run_tests () {
  before_all
  
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
