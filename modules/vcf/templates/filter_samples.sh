#!/bin/bash
filter_samples () {
  local args=()
  args+=("filter")
  args+=("--include" "!{params.vcf.filter_samples.split(',').collect(it -> "INFO/VIPC_S==\\\"" + it + "\\\"").join('||')}")
  args+=("--output" "!{vcfFilteredSamplesPath}")
  args+=("--output-type" "z")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfPath}")

  !{CMD_BCFTOOLS} "${args[@]}"
}

filter_samples
${CMD_BCFTOOLS} index "!{vcfFilteredSamplesPath}"
