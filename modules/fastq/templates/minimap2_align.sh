#!/bin/bash
set -euo pipefail

main() {
    !{CMD_MINIMAP2} -t "!{task.cpus}" -a -x sr "!{referenceMmi}" "!{fastqR1}" "!{fastqR2}" | \
    !{CMD_SAMTOOLS} fixmate -u -m - - | \
    !{CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" - | \
    !{CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index - "!{cram}"
}

main "$@"
