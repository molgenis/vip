#!/bin/bash
set -euo pipefail

normalize () {
  local args=()
  args+=("norm")
  args+=("--check-ref" "e")
  args+=("--fasta-ref" "!{refSeqPath}")
  args+=("--no-version")
  args+=("--output-type" "z")
  args+=("--output" "unsorted_!{vcfOut}")
  args+=("--old-rec-tag" "OLD_REC") # if variant is normalized, keep the original location in this field
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcf}")
  
  ${CMD_BCFTOOLS} "${args[@]}"
}

sort () {
  # sort since order can change due to normalization, cant pipe due to concurrent modification cause by 'norm' multithreading
  ${CMD_BCFTOOLS} sort --temp-dir . --max-mem "!{task.memory.toGiga() - 1}G" --output-type z --output "!{vcfOut}" "unsorted_!{vcfOut}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  normalize
  sort
  index
}

main "$@"