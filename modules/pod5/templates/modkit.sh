#!/bin/bash
set -euo pipefail

summary() {
  # Use modkit tool to summarize bam files
  ${CMD_MODKIT} summary !{sorted_bam} > !{summary_modkit}
}

adjust_mod() {
  ${CMD_MODKIT} adjust-mods !{sorted_bam} !{converted_bam} --convert h m
  ${CMD_SAMTOOLS} index -c !{converted_bam}
}

pileup() {
  # Use modkit tool to process bam to bedmethyl file
	${CMD_MODKIT} pileup !{converted_bam} !{bedmethyl} --cpg --ref !{reference} --only-tabs --log-filepath !{log_modkit}
}

main() {
  summary
  adjust_mod
  pileup    
}

main "$@"