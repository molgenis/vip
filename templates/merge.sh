#!/bin/bash
concat () {
  local args=()
  args+=("concat")
  args+=("--output-type" "z9")
  args+=("--output" "!{vcfMergedPath}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")

  !{singularity_bcftools} bcftools "${args[@]}" !{vcfPaths.join(' ')}
}

index () {
  local args=()
  args+=("index")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfMergedPath}")

  !{singularity_bcftools} bcftools "${args[@]}"
}

concat
index
