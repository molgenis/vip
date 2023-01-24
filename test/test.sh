#!/bin/bash

SCRIPT_DIR=$(dirname "$(realpath "$0")")

source "${SCRIPT_DIR}/test_vcf.sh"
mv output output_vcf
source "${SCRIPT_DIR}/test_cram.sh"
mv output output_cram
source "${SCRIPT_DIR}/test_fastq.sh"
mv output output_fastq
