#!/bin/bash
set -euo pipefail

sort() {
  ${CMD_SAMTOOLS} sort --no-PG -u -o small_X5_sorted.bam !{in} --write-index
}

main() {
  sort    
}

main "$@"