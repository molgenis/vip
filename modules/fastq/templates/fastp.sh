#!/bin/bash
set -euo pipefail

concatenate() {
  local args=()
  args+=("--force") # concatenate both compressed and uncompressed files
  args+=(!{fastqs})

  zcat "${args[@]}"
}

fastp() {
  local args=()
  args+=("--stdin")
  args+=("--out1" "!{fastqPass}")
  args+=("--failed_out" "!{fastqFail}")
  args+=("--html" "!{reportHtml}")
  args+=("--json" "!{reportJson}")
  args+=("--thread" "!{task.cpus}")
  if [[ -n "!{options}" ]]; then
    args+=(!{options})
  fi

  ${CMD_FASTP} "${args[@]}"

  # workaround: fastp can produce empty fastq.gz files that can't be used with gzip
  [ -s "!{fastqPass}" ] || rm "!{fastqPass}"
  [ -s "!{fastqFail}" ] || rm "!{fastqFail}"
}

main() {
  # prevent writing concatenated fastq to disk to reduce disk space usage
  concatenate | fastp
}

main "$@"
