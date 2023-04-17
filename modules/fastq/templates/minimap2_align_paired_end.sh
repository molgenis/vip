#!/bin/bash
set -euo pipefail

main() {
    !{params.CMD_MINIMAP2} -t "!{task.cpus}" -a -x sr "!{referenceMmi}" "!{fastqR1}" "!{fastqR2}" | \
    !{params.CMD_SAMTOOLS} fixmate -u -m - - | \
    !{params.CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" - | \
    !{params.CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index - "!{cram}"
}

main "$@"
