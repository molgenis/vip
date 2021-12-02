#!/bin/bash
filter () {
  local args=()
  args+=("filter")
  args+=("--include" "!{params.filter_classes.split(',').collect(it -> "VIPC==\\\"" + it + "\\\"").join('||')}")
  args+=("--output" "!{vcfFilteredPath}")
  args+=("--output-type" "z")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfPath}")

  !{singularity_bcftools} bcftools "${args[@]}"
}

filter
