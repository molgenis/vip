#!/bin/bash
set -euo pipefail

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

trap abort SIGINT
abort() {
   echo "execution aborted by user"
   exit 1
}

CMD_VIP="$(realpath "${SCRIPT_DIR}/../vip")"
CMD_NEXTFLOW="$(realpath "${SCRIPT_DIR}/../nextflow")"

TEST_DIR="${SCRIPT_DIR}"
TEST_RESOURCES_DIR="${TEST_DIR}/resources"
TEST_RESOURCES_DOWNLOADS_DIR="${TEST_RESOURCES_DIR}/downloads"
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

  if [ ${FAILED} -gt 0 ]; then
    echo -e "${RED}FAILED${NC} ${TEST_ID}"
  fi
}

before_each () {
  OUTPUT_DIR="${TEST_OUTPUT_DIR}/${TEST_ID}"
  OUTPUT_LOG="${TEST_OUTPUT_DIR}/${TEST_ID}/.nxf.log"
  mkdir -p "${OUTPUT_DIR}"
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

download_test_resource() {
  local -r file="${1}"

  local -r url="https://download.molgeniscloud.org/downloads/vip/test/resources/${file}"
  local -r output="${TEST_RESOURCES_DOWNLOADS_DIR}/${file}"

  if [ ! -f "${output}" ]; then
    mkdir -p "${TEST_RESOURCES_DOWNLOADS_DIR}"
    if ! wget --quiet --continue "${url}" --output-document "${output}"; then
      echo -e "an error occurred downloading ${url}"
        # wget always writes an (empty) output file regardless of errors
        rm -f "${output}"
        exit 1
    fi
  fi
}
