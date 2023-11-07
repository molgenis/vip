#!/bin/bash
set -euo pipefail

align() {
    local args=()
    args+=("-t" "!{task.cpus}")
    args+=("-a")
    # MarkDuplicates uses the LB (= DNA preparation library identifier) field to determine which read groups might contain molecular duplicates, in case the same DNA library was sequenced on multiple lanes.
    args+=("-R" "@RG\tID:$(basename !{fastqR1})\tPL:!{platform}\tLB:!{sampleId}\tSM:!{sampleId}")
    args+=("-x" "sr")
    if [[ "!{softClipping}" == "true" ]]; then
        args+=("-Y")
    fi
    args+=("!{referenceMmi}")
    args+=("!{fastqR1}" "!{fastqR2}") 

    ${CMD_MINIMAP2} "${args[@]}" | \
    ${CMD_SAMTOOLS} fixmate -u -m -@ "!{task.cpus}" - - | \
    #position sort for markdup
    ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" -o "!{cram}" --write-index -
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  align
  stats      
}

main "$@"
