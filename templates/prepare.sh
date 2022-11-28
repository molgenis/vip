#!/bin/bash
add_header () {
  printf "##VIP_Version=%s\n##VIP_Command=%s" "${VIP_VERSION}" "!{workflow.commandLine}" > "!{vcfPath}.header"

  local args=()
  args+=("annotate")
  args+=("--header-lines" "!{vcfPath}.header")
  args+=("--output-type" "z")
  args+=("--output" "!{vcfOutputPath}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfPath}")

  !{apptainer_bcftools} bcftools "${args[@]}"
}

index () {
  local args=()
  args+=("index")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfOutputPath}")

  !{apptainer_bcftools} bcftools "${args[@]}"
}

index_stats () {
  local args=()
  args+=("index")
  args+=("--stats")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfOutputPath}")

  !{apptainer_bcftools} bcftools "${args[@]}" > "!{vcfOutputPath}".stats
}

add_header
index
index_stats
