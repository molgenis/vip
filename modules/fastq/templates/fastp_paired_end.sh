#!/bin/bash
set -euo pipefail

interleave() {
  local fastq_r1=(!{fastqR1s})
  local fastq_r2=(!{fastqR2s})

  for ((i=0;i<!{fastqR1s.size()};i++)); do
    local args=()
    args+=("mergepe")
    args+=("${fastq_r1["${i}"]}")
    args+=("${fastq_r2["${i}"]}")

    ${CMD_SEQTK} "${args[@]}"
  done
}

fastp() {
  local args=()
  args+=("--stdin")
  args+=("--interleaved_in")
  args+=("--out1" "!{fastqPassR1}")
  args+=("--out2" "!{fastqPassR2}")
  args+=("--failed_out" "!{fastqFail}")
  args+=("--html" "!{reportHtml}")
  args+=("--json" "!{reportJson}")
  args+=("--thread" "!{task.cpus}")
  if [[ -n "!{options}" ]]; then
    args+=(!{options})
  fi

  ${CMD_FASTP} "${args[@]}"

  # workaround: fastp can produce empty fastq.gz files that can't be used with gzip
  [ -s "!{fastqPassR1}" ] || rm "!{fastqPassR1}"
  [ -s "!{fastqPassR2}" ] || rm "!{fastqPassR2}"
  [ -s "!{fastqFail}" ] || rm "!{fastqFail}"
}

main() {
  # prevent writing interleaved fastq to disk to reduce disk space usage
  interleave | fastp
}

main "$@"
