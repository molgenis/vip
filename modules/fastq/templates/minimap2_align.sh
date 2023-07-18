#!/bin/bash
set -euo pipefail

main() {
    local args=()
    args+=("-t" "!{task.cpus}")
    args+=("-a")
    if [[ -n "!{preset}" ]]; then
        args+=("-x" "!{preset}")
    fi
    if [[ "!{softClipping}" == "true" ]]; then
        args+=("-Y")
    fi
    args+=("!{referenceMmi}")
    args+=("!{fastq}")

    if [[ -n "!{preset}" ]] && [[ "!{preset}" == "map-ont" ]]; then
      ${CMD_MINIMAP2} "${args[@]}" | ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" --reference "!{reference}" -o "!{cram}" --write-index -
    else
      ${CMD_MINIMAP2} "${args[@]}" | ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" - | ${CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index - "!{cram}"
    fi    
}

main "$@"
