#!/bin/bash
split () {
  local args=()
  args+=("view")
  args+=("--regions" "!{contig}")
  args+=("--output-type" "z")
  args+=("--output-file" "!{vcfRegionPath}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfPath}")

  !{singularity_bcftools} bcftools "${args[@]}"
}

split
