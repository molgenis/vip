#!/bin/bash
set -euo pipefail

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

source "${SCRIPT_DIR}/test_vcf.sh"
mv output output_vcf
source "${SCRIPT_DIR}/test_cram.sh"
mv output output_cram
source "${SCRIPT_DIR}/test_fastq.sh"
mv output output_fastq
