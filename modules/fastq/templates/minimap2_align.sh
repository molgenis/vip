#!/bin/bash
set -euo pipefail

align() {
  local args_fastp=()
  args_fastp+=("--thread" "!{task.cpus}")
  if [[ "!{disable_quality_filtering}" == "true"  ]]; then
      args_fastp+=("--disable_quality_filtering")
  fi
  if [[ "!{disable_length_filtering}" == "true"  ]]; then
      args_fastp+=("--disable_length_filtering")
  fi
  if [[ -n "!{additional_params}" ]]; then
      args_fastp+=("!{additional_params}")
  fi
  args_fastp+=("--html" "!{reportFile}")
  args_fastp+=("--in1" "!{fastq}")
  
  local args=()
  args+=("-t" "!{task.cpus}")
  args+=("-a")
  # MarkDuplicates uses the LB (= DNA preparation library identifier) field to determine which read groups might contain molecular duplicates, in case the same DNA library was sequenced on multiple lanes.
  args+=("-R" "@RG\tID:$(basename !{fastq})\tPL:!{platform}\tLB:!{sampleId}\tSM:!{sampleId}")
  if [[ -n "!{preset}" ]]; then
      args+=("-x" "!{preset}")
  fi
  if [[ "!{softClipping}" == "true" ]]; then
      args+=("-Y")
  fi
  args+=("!{referenceMmi}")

  ${CMD_FASTP} "${args_fastp[@]}" | ${CMD_MINIMAP2} "${args[@]}" | ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" --reference "!{reference}" -o "!{cram}" --write-index -
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

publish_fastp() {
  mkdir -p "!{outputPath}"
  cp "!{reportFile}" "!{outputPath}/!{reportFile}"
}

main() {
  align
  publish_fastp
  stats
}

main "$@"
