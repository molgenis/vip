#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/test_utils.sh"

test_giab_NA12878_illumina_hiseq_exome () {
  local -r base_url="ftp://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data"

  declare -A files=()
  files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7035_TAAGGCGA_L001_R1_001_trimmed.fastq.gz"]="9195dceb8b97564915b9a67c8b8a5271"
  files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7035_TAAGGCGA_L001_R2_001_trimmed.fastq.gz"]="c32ea5571d48e339dc4a21b762e89cb6"
  files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7035_TAAGGCGA_L002_R1_001_trimmed.fastq.gz"]="5a08668e4ccf75f3ad24a7012d56d821"
  files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7035_TAAGGCGA_L002_R2_001_trimmed.fastq.gz"]="3ff1caf9a2b9824f1f855f8be7ceb042"
  files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7086_CGTACTAG_L001_R1_001_trimmed.fastq.gz"]="5e36556544aabfc66c1ce7fb28d1d5b9"
  files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7086_CGTACTAG_L001_R2_001_trimmed.fastq.gz"]="38bde678b2dd73ec8a2b07d48e1421f8"
  files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7086_CGTACTAG_L002_R1_001_trimmed.fastq.gz"]="d3519eb5b12d2248afb65431908412a1"
  files["${base_url}/NA12878/Garvan_NA12878_HG001_HiSeq_Exome/NIST7086_CGTACTAG_L002_R2_001_trimmed.fastq.gz"]="efb711af9498c2d11c406f9bd06b0c0a"

  for i in "${!files[@]}"; do
    download "${i}" "${files[$i]}"
  done

  local args=()
  args+=("--workflow" "fastq")
  args+=("--input" "${TEST_RESOURCES_DIR}/giab_NA12878_illumina_hiseq_exome.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}"; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

test_giab_AshkenazimTrio_pacbio_ccs () {
  local -r base_url="ftp://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data"

  declare -A files=()
  files["${base_url}/AshkenazimTrio/HG002_NA24385_son/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG002.SequelII.merged_15kb_20kb.pbmm2.GRCh38.haplotag.10x.bam"]="d303b337a2e9ffedef0f2ad894078ac6"
  files["${base_url}/AshkenazimTrio/HG003_NA24149_father/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG003.SequelII.merged_15kb_20kb.pbmm2.GRCh38.haplotag.10x.bam"]="5d0ff146b26d403dac982a88028bb6bd"
  files["${base_url}/AshkenazimTrio/HG004_NA24143_mother/PacBio_CCS_15kb_20kb_chemistry2/GRCh38/HG004.SequelII.merged_15kb_20kb.pbmm2.GRCh38.haplotag.10x.bam"]="fd6d3806997c74eb539f2b7f47dab2ab"

  for i in "${!files[@]}"; do
    download "${i}" "${files[$i]}"
  done

  local args=()
  args+=("--workflow" "cram")
  args+=("--input" "${TEST_RESOURCES_DIR}/giab_AshkenazimTrio_pacbio_ccs.tsv")
  args+=("--output" "${OUTPUT_DIR}")
  args+=("--resume")

  if ! "${CMD_VIP}" "${args[@]}"; then
    return 1
  fi

  if [ ! "$(zcat "${OUTPUT_DIR}/vip.vcf.gz" | grep -vc "^#")" -gt 0 ]; then
    return 1
  fi
}

run_tests () {
  before_all

  TEST_ID="giab_NA12878_illumina_hiseq_exome"
  before_each
  test_giab_NA12878_illumina_hiseq_exome
  after_each

  TEST_ID="giab_AshkenazimTrio_pacbio_ccs"
  before_each
  test_giab_AshkenazimTrio_pacbio_ccs
  after_each

  after_all
}

main () {
  run_tests
}

main "${@}"
