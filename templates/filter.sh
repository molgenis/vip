#!/bin/bash
filter () {
  local args_split=()
  args_split+=("+split-vep")
  args_split+=("-c" "VIPC")
  args_split+=("--output" "!{vcfSplittedPath}")
  args_split+=("!{vcfPath}")

  !{singularity_bcftools} bcftools "${args_split[@]}"

  local args=()
  args+=("filter")
  args+=("--include" "!{params.filter_classes.split(',').collect(it -> "VIPC[*]==\\\"" + it + "\\\"").join('||')}")
  args+=("--output" "!{vcfFilteredPath}")
  args+=("--output-type" "z")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfSplittedPath}")

  !{singularity_bcftools} bcftools "${args[@]}"
}

filter
