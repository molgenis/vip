#!/bin/bash
norm () {
  local args=()
  args+=("norm")
  # split multi-allelic sites into bi-allelic records (both SNPs and indels are merged separately into two records)
  args+=("--multiallelics" "-both")
  # warn when incorrect or missing REF allele is encountered or when alternate allele is non-ACGTN (e.g. structural variant)
  args+=("--check-ref" "w")
  args+=("--fasta-ref" "!{refSeqPath}")
  args+=("--output-type" "z")
  args+=("--output" "!{vcfPreprocessedPath}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfPath}")

  !{apptainer_bcftools} bcftools "${args[@]}"
}

norm
