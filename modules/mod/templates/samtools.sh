#!/bin/bash
set -euo pipefail

sort() {
  # Use samtools to sort bam
  ${CMD_SAMTOOLS} sort --no-PG -u -o !{sortedBam} !{bam} --write-index
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{sortedBam}" > "!{sortedBamStats}"
}

main() {
  sort
  stats    
}

main "$@"