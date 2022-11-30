#!/bin/bash
concat () {
  local args=()
  args+=("concat")
  args+=("--output-type" "z9")
  args+=("--output" "!{vcfMergedPath}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")

  !{apptainer_bcftools} bcftools "${args[@]}" !{vcfPaths.join(' ')}
}

index () {
  local args=()
  args+=("index")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfMergedPath}")

  !{apptainer_bcftools} bcftools "${args[@]}"
}

concat
index
