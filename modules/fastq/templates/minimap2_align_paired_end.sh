#!/bin/bash
set -euo pipefail

align() {
       local args=()
    args+=("-t" "!{task.cpus}")
    args+=("-a")
    args+=("-x" "sr")
    if [[ "!{softClipping}" == "true" ]]; then
        args+=("-Y")
    fi
    args+=("!{referenceMmi}")
    args+=("!{fastqR1}" "!{fastqR2}") 

    ${CMD_MINIMAP2} "${args[@]}" | \
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
