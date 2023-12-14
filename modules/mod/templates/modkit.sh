#!/bin/bash
set -euo pipefail

summary() {
  # Use modkit tool to summarize bam files
  ${CMD_MODKIT} summary !{sorted_bam} > !{summary_modkit}
}

pileup() {
  # Use modkit tool to process bam to bedmethyl file
	${CMD_MODKIT} pileup !{sorted_bam} !{bed} --ref !{reference} --only-tabs --log-filepath !{log_modkit}
}

main() {
  summary
  pileup    
}

main "$@"