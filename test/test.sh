#!/bin/bash
SCRIPT_DIR=$(dirname "$(realpath "$0")")

trap abort SIGINT
abort() {
   echo "execution aborted by user"
   exit 1
}

NXF_VERSION="21.10.6"

TEST_DIR="${SCRIPT_DIR}"
TEST_RESOURCES_DIR="${TEST_DIR}/resources"
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

test_snv () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh37")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv.vcf")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/snv.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
    return 1
  fi
}

test_snv_proband () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh37")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv_proband.vcf")
  args+=("--probands" "PROBAND0")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/snv_proband.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
    return 1
  fi
}

test_snv_proband_trio () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh37")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv_proband_trio.vcf")
  args+=("--probands" "PROBAND0")
  args+=("--phenotypes" "HP:0001250;HP:0001166")
  args+=("--pedigree" "${TEST_RESOURCES_DIR}/snv_proband_trio.ped")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/snv_proband_trio.vcf.gz" | grep -vc "^#")" -eq 2 ]; then
    return 1
  fi
}

test_snv_proband_trio_b38 () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh38")
  args+=("--input" "${TEST_RESOURCES_DIR}/snv_proband_trio_b38.vcf")
  args+=("--probands" "PROBAND0")
  args+=("--pedigree" "${TEST_RESOURCES_DIR}/snv_proband_trio.ped")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/snv_proband_trio_b38.vcf.gz" | grep -vc "^#")" -eq 2 ]; then
    return 1
  fi
}

test_sv () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh37")
  args+=("--input" "${TEST_RESOURCES_DIR}/sv.vcf")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/sv.vcf.gz" | grep -vc "^#")" -eq 1 ]; then
    return 1
  fi
}

test_lp () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh37")
  args+=("--input" "${TEST_RESOURCES_DIR}/lp.vcf.gz")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--GRCh37_annotate_vep_plugin_vkgl" "${TEST_RESOURCES_DIR}/vkgl_public_consensus_empty.tsv")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/lp.vcf.gz" | grep -vc "^#")" -lt 2446 ]; then
    return 1
  fi
}

test_lp_b38 () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh38")
  args+=("--input" "${TEST_RESOURCES_DIR}/lp_b38.vcf.gz")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--GRCh38_annotate_vep_plugin_vkgl" "${TEST_RESOURCES_DIR}/vkgl_public_consensus_empty.tsv")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/lp_b38.vcf.gz" | grep -vc "^#")" -lt 2441 ]; then
    return 1
  fi
}

test_lb () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh37")
  args+=("--input" "${TEST_RESOURCES_DIR}/lb.bcf.gz")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--GRCh37_annotate_vep_plugin_vkgl" "${TEST_RESOURCES_DIR}/vkgl_public_consensus_empty.tsv")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/lb.vcf.gz" | grep -vc "^#")" -gt 1273 ]; then
    return 1
  fi
}

test_lb_b38 () {
  local args=()
  args+=("-log" "${OUTPUT_LOG}")
  args+=("run")
  args+=("--assembly" "GRCh38")
  args+=("--input" "${TEST_RESOURCES_DIR}/lb_b38.bcf.gz")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--GRCh38_annotate_vep_plugin_vkgl" "${TEST_RESOURCES_DIR}/vkgl_public_consensus_empty.tsv")
  args+=("${SCRIPT_DIR}/../main.nf")

  if ! NXF_VER="${NXF_VERSION}" nextflow "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ "$(zcat "${OUTPUT_DIR}/lb_b38.vcf.gz" | grep -vc "^#")" -gt 1176 ]; then
    return 1
  fi
}

run_tests () {
  before_all

  TEST_ID="test_snv"
  before_each
  test_snv
  after_each

  TEST_ID="test_snv_proband"
  before_each
  test_snv_proband
  after_each

  TEST_ID="test_snv_proband_trio"
  before_each
  test_snv_proband_trio
  after_each

  TEST_ID="test_snv_proband_trio_b38"
  before_each
  test_snv_proband_trio_b38
  after_each

  TEST_ID="test_sv"
  before_each
  test_sv
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
  if ! command -v nextflow &> /dev/null; then
    echo -e "command 'nextflow' could not be found"
    exit 2
  fi
  if [ -z "${SINGULARITY_BIND}" ]; then
    echo -e "${YELLOW}WARNING: SINGULARITY_BIND environment variable not found${NC}"
  fi

  run_tests
}

main "${@}"
