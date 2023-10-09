#!/bin/bash
set -euo pipefail

# handle interrupt from keyboard
trap abort SIGINT

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(realpath "$(dirname "$0")")"
TEST_SUITES_DIR="${SCRIPT_DIR}/suites"
EXECUTION_DIR="${PWD}"

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m"

usage() {
  echo -e "usage: ${SCRIPT_NAME} [-t <arg>]
  -t, --test    <arg>    Tests to run (comma-separated). examples: 'vcf', 'cram,fastq', '*/*b38'
  -h, --help             Print this message and exit"
}

declare -A jobs
declare -A jobs_status
declare -A tests_dir
declare -A tests_status

abort() {
  echo -e "execution aborted by user"
  echo -e "cancelling jobs ..."
   
  local job_id
  for case in "${!jobs[@]}"; do
    job_id="${jobs["${case}"]}"
    scancel "${job_id}"
  done

  exit 1
}

run() {
  local -r test="${1}"
  IFS=',' read -r -a test_cases <<< "${test}"

  local cases=()
  for suite in "${TEST_SUITES_DIR}/"*; do
    if [[ -d "${suite}" ]]; then
      for case in "${suite}/"*; do
        if [[ -f "${case}" ]]; then
          
          if [[ ${#test_cases[@]} == "0" ]]; then
            # always include case if case no input tests defined
            cases+=("${case}")
          else
            # include case if it matches an input test
            for test_case in "${test_cases[@]}"; do
              # if input test doesn't contain a slash assume that input is a test suite
              # check if case is part of the suite
              if [[ ${test_case} != *"/"* ]]; then
                test_case="${test_case}/*"
              fi
              if [[ "${case}" == "${TEST_SUITES_DIR}"/${test_case}*.sh ]]; then
                cases+=("${case}")
                break
              fi
            done
          fi

        fi
      done
    fi
  done

  if [[ ${#test_cases[@]} != "0" && "${#cases[@]}" == 0 ]]; then
    echo -e "error: no tests found that match -t --test '${test}'"
    exit 1
  fi

  echo "running tests ..."
  
  local -r vip_dir="$(realpath "${SCRIPT_DIR}/..")"
  local -r tests_output_dir="${SCRIPT_DIR}/output"
  
  # submit test jobs
  local case_id
  local job_id
  local test_output_dir
  local test_resources_dir
  for case in "${cases[@]}"; do
    case_id="${case#"${TEST_SUITES_DIR}/"}"
    case_id=${case_id%".sh"}

    test_output_dir="${tests_output_dir}/${case_id}"
    if [[ -d "${test_output_dir}" ]]; then
      # only remove certain output test files so that --resume uses cached results
      rm -f "${test_output_dir}/.exitcode" "${test_output_dir}/job.err" "${test_output_dir}/job.out" "${test_output_dir}/.nxf.log"
    else
      mkdir -p "${test_output_dir}"
    fi
    test_resources_dir="$(dirname "${case}")/resources"

    local time="${SLURM_TIMELIMIT:-"05:59:59"}"
    local sbatch_args=()
    sbatch_args+=("--parsable")
    sbatch_args+=("--job-name=vip_test")
    sbatch_args+=("--time=${time}")
    sbatch_args+=("--cpus-per-task=1")
    sbatch_args+=("--mem=1gb")
    sbatch_args+=("--nodes=1")
    sbatch_args+=("--open-mode=append")
    sbatch_args+=("--export=PATH=${vip_dir}:${PATH},VIP_DIR=${vip_dir},TMPDIR=${test_output_dir}/tmp,NXF_HOME=${tests_output_dir}/nextflow/home,NXF_TEMP=${tests_output_dir}/nextflow/temp,NXF_WORK=${tests_output_dir}/nextflow/work,OUTPUT_DIR=${test_output_dir},TEST_RESOURCES_DIR=${test_resources_dir},TEST_UTILS_DIR=${SCRIPT_DIR}")
    sbatch_args+=("--get-user-env=L")
    sbatch_args+=("--output=${test_output_dir}/job.out")
    sbatch_args+=("--error=${test_output_dir}/job.err")
    sbatch_args+=("--chdir=${vip_dir}")
    sbatch_args+=("${case}")
    
    job_id="$(sbatch "${sbatch_args[@]}")"

    jobs["${case}"]="${job_id}"
    tests_dir["${job_id}"]="${test_output_dir}"
  done

  for case in "${!jobs[@]}"; do
    job_id="${jobs["${case}"]}"
    jobs_status[${job_id}]=""
  done

  # check and update status of submitted jobs
  local job_status
  local test_dir
  local test_exitcode
  local is_running

  while true; do
    # update status of jobs
    for job_id in "${!jobs_status[@]}"; do
        job_status="${jobs_status["${job_id}"]}"

        # retrieve status for non-terminal jobs
        if [[ "${job_status}" != "COMPLETED" && "${job_status}" != "FAILED" && "${job_status}" != "CANCELLED" && "${job_status}" != "PREEMPTED" ]]; then
          job_status="$(sacct -j "${job_id}" -o State | awk 'FNR == 3 {print $1}')"
          jobs_status[${job_id}]="${job_status}"

          # for completed jobs store the test exitcode
          if [[ "${job_status}" == "COMPLETED" ]]; then
            test_dir="${tests_dir["${job_id}"]}"

            test_exitcode_file="${test_dir}/.exitcode"
            if [[ -f "${test_exitcode_file}" ]]; then
              test_exitcode="$(<"${test_exitcode_file}")"
            else
              >&2 echo -e "error: completed test did not produce file '${test_exitcode_file}'"
              test_exitcode="1"
            fi

            tests_status[${job_id}]="${test_exitcode}"
          fi
        fi
    done

    # update progress on stdout
    local job_status_display
    local case_id
    local test_result_display
    local test_result_color
    local test_status
    local log_display
    
    for case in "${cases[@]}"; do
      case_id="${case#"${TEST_SUITES_DIR}/"}"
      case_id=${case_id%".sh"}

      job_id="${jobs["${case}"]}"

      job_status="${jobs_status["${job_id}"]}"
      if [[ "${job_status}" != "" ]]; then
        job_status_display="${job_status,,}"
      else
        job_status_display="submitted"
      fi

      if [[ "${job_status}" == "COMPLETED" ]]; then
        test_status="${tests_status["${job_id}"]}"
        if [[ "${test_status}" -eq "0" ]]; then
          test_result_display="PASSED"
          test_result_color="${GREEN}"
        else
          test_result_display="FAILED"
          test_result_color="${RED}"
        fi
      elif [[ "${job_status}" == "FAILED" || "${job_status}" == "CANCELLED" || "${job_status}" == "PREEMPTED" ]]; then
        test_result_display="KAPUTT"
        test_result_color="${YELLOW}"
      else
        test_result_display=""
        test_result_color="${NC}"
      fi

      log_display="$(realpath --relative-to="${EXECUTION_DIR}" "${tests_output_dir}/${case_id}/.nxf.log")"
      printf "\e[0K%-40s | ${test_result_color}%-6s${NC} | %s=%-9s %s\n" "${case_id}" "${test_result_display}" "${job_id}" "${job_status_display}" "${log_display}"
    done
    
    # determine if jobs are still running
    is_running=false
    for job_id in "${!jobs_status[@]}"; do
        job_status="${jobs_status["${job_id}"]}"
        if [[ "${job_status}" != "COMPLETED" && "${job_status}" != "FAILED" && "${job_status}" != "CANCELLED" && "${job_status}" != "PREEMPTED" ]]; then
          is_running=true
          break
        fi
    done

    # all jobs are in terminal state
    if [[ "${is_running}" == false ]]; then
        break
    fi

    # take a break before checking again
    sleep 1

    for job_id in "${!jobs[@]}"; do
      echo -ne '\033M' # scroll up one line using ANSI/VT100 cursor control sequences 
    done
  done

  echo "done"

  # determine exit code
  for job_id in "${!jobs_status[@]}"; do
    job_status="${jobs_status["${job_id}"]}"
    if [[ "${job_status}" != "COMPLETED" ]]; then
      return 1
    fi
    test_status="${tests_status["${job_id}"]}"
    if [[ "${test_status}" != "0" ]]; then
      return 1
    fi
  done
        
  return 0
}

validate() {
  local -r test="${1}"

  if ! command -v sbatch &> /dev/null; then
    echo -e "error: tests require 'sbatch' in order to run"
    exit 1
  fi
  if ! command -v scancel &> /dev/null; then
    echo -e "error: tests require 'scancel' in order to run"
    exit 1
  fi
  if ! command -v sacct &> /dev/null; then
    echo -e "error: tests require 'scancel' in order to run"
    exit 1
  fi
}

main() {
  local -r args=$(getopt -a -n pipeline -o t:h --long test:,help -- "$@")
  # shellcheck disable=SC2181
  if [[ $? != 0 ]]; then
    usage
    exit 2
  fi

  local test="cram,fastq,gvcf,vcf"

  eval set -- "${args}"
  while :; do
    case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    -t | --test)
      test="$2"
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

  validate "${test}"
  run "${test}"
}

main "$@"