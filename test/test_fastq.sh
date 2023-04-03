#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

source ${SCRIPT_DIR}/test_utils.sh

test_fastq_pacbio_hifi () {
  download_test_resource "m54238_180628_014238_s0_10000.Q20.fastq.gz"

  echo -e "params { vcf.filter.classes = \"B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "fastq")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/fastq_pacbio_hifi.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--profile" "local")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_fastq_nanopore () {
  download_test_resource "GM24385_1_s0_10000.fastq.gz"
  download_test_resource "GM24385_2_s0_10000.fastq.gz"
  download_test_resource "GM24385_3_s0_10000.fastq.gz"
  
  echo -e "params { vcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"

  local args=()
  args+=("--workflow" "fastq")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/fastq_nanopore.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_fastq_illumina_pairedend () {
  download_test_resource "NIST7035_TAAGGCGA_L001_R1_001_s0_10000.fastq.gz"
  download_test_resource "NIST7035_TAAGGCGA_L001_R2_001_s0_10000.fastq.gz"
  download_test_resource "NIST7035_TAAGGCGA_L002_R1_001_s0_10000.fastq.gz"
  download_test_resource "NIST7035_TAAGGCGA_L002_R2_001_s0_10000.fastq.gz"
  download_test_resource "NIST7086_CGTACTAG_L001_R1_001_s0_10000.fastq.gz"
  download_test_resource "NIST7086_CGTACTAG_L001_R2_001_s0_10000.fastq.gz"
  download_test_resource "NIST7086_CGTACTAG_L002_R1_001_s0_10000.fastq.gz"
  download_test_resource "NIST7086_CGTACTAG_L002_R2_001_s0_10000.fastq.gz"

  echo -e "params { vcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"
  
  local args=()
  args+=("--workflow" "fastq")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/fastq_illumina_pairedend.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}" > /dev/null 2>&1; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_fastq_illumina_pairedend_trio () {
  download_test_resource "HG002.novaseq.pcr-free.35x.R1_s0_10000.fastq.gz"
  download_test_resource "HG002.novaseq.pcr-free.35x.R2_s0_10000.fastq.gz"
  download_test_resource "HG003.novaseq.pcr-free.35x.R1_s0_10000.fastq.gz"
  download_test_resource "HG003.novaseq.pcr-free.35x.R2_s0_10000.fastq.gz"
  download_test_resource "HG004.novaseq.pcr-free.35x.R1_s0_10000.fastq.gz"
  download_test_resource "HG004.novaseq.pcr-free.35x.R2_s0_10000.fastq.gz"

  echo -e "params { vcf.filter.classes = \"LQ,B,LB,VUS,LP,P\"\nvcf.filter_samples.classes = \"LQ,MV,OK\" }" > "${OUTPUT_DIR}/custom.cfg"
  
  local args=()
  args+=("--workflow" "fastq")
  args+=("--config" "${OUTPUT_DIR}/custom.cfg")
  args+=("--input" "${TEST_RESOURCES_DIR}/fastq_illumina_pairedend_trio.tsv")
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

  TEST_ID="fastq_pacbio_hifi"
  before_each
  test_fastq_pacbio_hifi
  after_each

  TEST_ID="fastq_nanopore"
  before_each
  test_fastq_nanopore
  after_each

  TEST_ID="fastq_illumina_pairedend"
  before_each
  test_fastq_illumina_pairedend
  after_each

  TEST_ID="fastq_illumina_pairedend_trio"
  before_each
  test_fastq_illumina_pairedend_trio
  after_each

  after_all
}

main () {
  run_tests
}

main "${@}"
