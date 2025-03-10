#!/bin/bash
set -euo pipefail

normalize () {
  local args=()
  args+=("norm")
  # throw error or warn when incorrect or missing REF allele is encountered or when alternate allele is non-ACGTN (e.g. structural variant)
  if [ "!{allowInvalidRef}" = true  ]; then
    args+=("--check-ref" "w")
  else
    args+=("--check-ref" "e")
  fi
  args+=("--fasta-ref" "!{refSeqPath}")
  args+=("--output-type" "z")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--old-rec-tag" "OLD_REC") # if variant is normalized, keep the original location in this field
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcf}")

  ${CMD_BCFTOOLS} "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  normalize
  index
}

main "$@"