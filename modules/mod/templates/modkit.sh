#!/bin/bash
set -euo pipefail

summary() {
  ${CMD_MODKIT} summary !{in} > modkit_X5_summary.txt
}

pileup() {
	${CMD_MODKIT} pileup !{in} small_X5_cpg.bed --cpg --ref !{params.reference_g1k_v37}
}

main() {
  summary
  pileup    
}

main "$@"