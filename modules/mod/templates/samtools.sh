#!/bin/bash
set -euo pipefail

sort() {
  ${CMD_SAMTOOLS} sort --no-PG -u -o !{params.run}_sorted.bam !{in} --write-index
}

main() {
  sort    
}

main "$@"