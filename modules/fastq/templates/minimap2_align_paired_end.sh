#!/bin/bash
set -euo pipefail

align() {
    local args=()
    args+=("-t" "!{task.cpus}")
    args+=("-a")
    args+=("-R" "@RG\tID:$(basename !{fastqR1})\tPL:!{platform}\tLB:!{sampleId}\tSM:!{sampleId}")
    args+=("-x" "sr")
    if [[ "!{softClipping}" == "true" ]]; then
        args+=("-Y")
    fi
    args+=("!{referenceMmi}")
    args+=("!{fastqR1}" "!{fastqR2}") 

    ${CMD_MINIMAP2} "${args[@]}"
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  align
  stats      
}

main "$@"
