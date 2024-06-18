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
    args+=("!{fastqR1}")
    args+=("!{fastqR2}")

    if [[ "!{markDuplicates}" == "true" ]]; then
      ${CMD_MINIMAP2} "${args[@]}" | \
        ${CMD_SAMTOOLS} fixmate -u -m -@ "!{task.cpus}" --no-PG - - | \
        ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" --reference "!{reference}" --no-PG - | \
        ${CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --no-PG --write-index - "!{cram}"
    else
      ${CMD_MINIMAP2} "${args[@]}" |\
        ${CMD_SAMTOOLS} fixmate -u -m -@ "!{task.cpus}" --no-PG - - | \
        ${CMD_SAMTOOLS} sort -@ "!{task.cpus}" --reference "!{reference}" -o "!{cram}" --no-PG --write-index -
    fi
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  align
  stats
}

main "$@"
