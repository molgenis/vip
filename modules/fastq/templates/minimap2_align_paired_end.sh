#!/bin/bash
set -euo pipefail

align() {
    ${CMD_MINIMAP2} -t "!{task.cpus}" -a -x sr "!{referenceMmi}" "!{fastqR1}" "!{fastqR2}" | \
    ${CMD_SAMTOOLS} fixmate -u -m - - | \
    ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" - | \
    ${CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index - "!{cram}"
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  align
  stats      
}

main "$@"
