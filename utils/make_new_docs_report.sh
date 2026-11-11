#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SHEET_DIR="${PWD}"


usage() {
  echo -e "usage: ${SCRIPT_NAME}
  -d, --datadir    <arg>    Path to the datadir to use for building the report
  -o, --output     <arg>    Path to the output directory
  -p, --prmdir     <arg>    Path to the prm dir containing the fastq data folders
  -r, --repo       <arg>    Path to vip repo to use for running report
  -h, --help                Print this message and exit"
}


copy_data() {
  local -r prm_dir="${1}"
  local -r data_dir="${2}/fastq"

  echo -e "Rsyncing ${prm_dir}*.fastq.gz into ${data_dir}"
  rsync -a "${prm_dir}*.fastq.gz" "${data_dir}"
}


make_sample_sheet() {
  local -r data_dir="${1}"

cat << EOF > new_report_samplesheet.tsv
family_id	individual_id	paternal_id	maternal_id	proband	sex	affected	hpo_ids	sequencing_platform	sequencing_method	fastq_r1	fastq_r2	pcr_performed
AshkenazimTrio	HG002	HG003	HG004	true	male	true	HP:0004383,HP:0045017,HP:0001627	illumina	WES	${data_dir}/fastq/HG002_R1.fastq.gz	${data_dir}/fastq/HG002_R2.fastq.gz	true
AshkenazimTrio	HG003			false	male	false		illumina	WES	${data_dir}/fastq/HG003_R1.fastq.gz	${data_dir}/fastq/HG003_R2.fastq.gz	true
AshkenazimTrio	HG004			false	female	true	HP:0004383,HP:0045017,HP:0001627	illumina	WES	${data_dir}/fastq/HG004_R1.fastq.gz	${data_dir}/fastq/HG004_R2.fastq.gz	true
EOF
}


validate() {
  local -r prm_dir="${1}"
  local -r data_dir="${2}"
  local -r repo_folder="${3}"
  local -r output_folder="${4}"
  
  # Check if the prm_dir exists
  if [[ ! -d "${prm_dir}" ]]; then
    echo -e "-p, --prmdir '${prm_dir}' does not exist"
    exit 2
  fi
  
  # Check if the data_dir exists
  if [[ ! -d "${data_dir}" ]]; then
    echo -e "-d, --datadir '${data_dir}' does not exist"
    exit 2
  fi
  
  # Check if output folder exists
  if [[ ! -d "${output_folder}" ]]; then
    echo -e "-o, --output '${output_folder}' does not exist"
    exit 2
  fi
  
  # Check if the repo folder exists
  if [[ -n "${repo_folder}" ]] && [[ ! -d "${repo_folder}" ]]; then
    echo -e "-r, --repo folder '${repo_folder}' does not exist"
    exit 2
  fi
}


run_vip_module() {
  local -r output_folder="${1}"
  
  ml vip
  vip --workflow fastq --input "${SHEET_DIR}/new_report_samplesheet.tsv" --output "${output_folder}" --resume
}


run_vip_repo() {
  local -r repo_folder="${1}"
  local -r output_folder="${2}"
  
  ml Java
  
  cd "${repo_folder}"
  sh vip.sh --workflow fastq --input "${SHEET_DIR}/new_report_samplesheet.tsv" --output "${output_folder}" --resume
}


main() {
  local -r args=$(getopt -a -n make_report -o d:o:p:r:h --long datadir:,output:,prmdir:,repo:,help -- "$@")
  
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi
  
  local prm_dir=""
  local data_dir=""
  local repo_folder=""
  local output_folder=""
  
  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -d | --datadir)
      data_dir="$2"
      shift 2
      ;;
    -o | --output)
      output_folder="$2"
      shift 2
      ;;
    -p | --prmdir)
      prm_dir="$2"
      shift 2
      ;;
    -r | --repo)
      repo_folder="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      exit 2
      ;;
    esac
  done
  
  
  validate "${prm_dir}" "${data_dir}" "${repo_folder}" "${output_folder}"
  copy_data "${prm_dir}" "${data_dir}"
  make_sample_sheet "${data_dir}"
  
  if [[ -n "${repo_folder}" ]]; then
    run_vip_repo "${repo_folder}" "${output_folder}"
  else
    run_vip_module "${output_folder}"
  fi
  echo -e "Check the output directory ${output_folder} for your new report"
}


main "${@}"
