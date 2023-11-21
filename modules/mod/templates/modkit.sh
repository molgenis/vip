#!/bin/bash
set -euo pipefail

summary() {
  ${CMD_MODKIT} summary !{in} > !{params.run}_summary.txt
}

pileup() {
	${CMD_MODKIT} pileup !{in} !{params.run}_cpg.bed --cpg --ref !{params.reference_g1k_v37} --log-filepath !{params.run}_modkit.log
}

main() {
  summary
  pileup    
}

main "$@"