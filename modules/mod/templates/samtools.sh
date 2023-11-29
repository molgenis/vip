#!/bin/bash
set -euo pipefail

sort() {
  # Use samtools to sort bam
  ${CMD_SAMTOOLS} sort --no-PG -u -o !{sorted_bam} !{bam} --write-index
}

main() {
  sort    
}

main "$@"