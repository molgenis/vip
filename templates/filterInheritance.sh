#!/bin/bash
filter () {
  local args=()
  args+=("filter")
  args+=("--include" "FMT/VIM=1 | FMT/VID=1")
  args+=("--output" "!{vcfFilteredPath}")
  args+=("--output-type" "z")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfPath}")

  !{singularity_bcftools} bcftools "${args[@]}"
}

filter
