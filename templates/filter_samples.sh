#!/bin/bash
filter_samples () {
  local args=()
  args+=("filter")
  args+=("--include" "!{params.filter_samples_classes.split(',').collect(it -> "VIPC_S==\\\"" + it + "\\\"").join('||')}")
  args+=("--output" "!{vcfFilteredSamplesPath}")
  args+=("--output-type" "z")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfPath}")

  !{singularity_bcftools} bcftools "${args[@]}"
}

filter_samples
