#!/bin/bash
set -euo pipefail

normalize () {
  local args=()
  args+=("norm")
  # split multi-allelic sites into bi-allelic records (both SNPs and indels are merged separately into two records)
  args+=("--multiallelics" "-both")
  # warn when incorrect or missing REF allele is encountered or when alternate allele is non-ACGTN (e.g. structural variant)
  args+=("--check-ref" "w")
  args+=("--fasta-ref" "!{refSeqPath}")
  args+=("--output-type" "z")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcf}")

  !{params.CMD_BCFTOOLS} "${args[@]}"
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  normalize
  index
}

main "$@"