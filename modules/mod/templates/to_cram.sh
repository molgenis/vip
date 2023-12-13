#!/bin/bash
set -euo pipefail

to_cram() {
  ${CMD_SAMTOOLS} view -C -T !{reference} --no-PG -o !{cram} !{sorted_bam} --write-index
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  to_cram
  stats    
}

main "$@"