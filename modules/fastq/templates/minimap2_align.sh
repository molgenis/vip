#!/bin/bash
set -euo pipefail

main() {
    local args=()
    args+=("-t" "!{task.cpus}")
    args+=("-a")
    if [[ -n "!{preset}" ]]; then
        args+=("-x" "!{preset}")
    fi
    args+=("!{referenceMmi}")
    args+=("!{fastq}")

    if [[ -n "!{preset}" ]] && [[ "!{preset}" == "map-ont" ]]; then
      !{params.CMD_MINIMAP2} "${args[@]}" | !{params.CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" --reference "!{reference}" -o "!{cram}" --write-index -
    else
      !{params.CMD_MINIMAP2} "${args[@]}" | !{params.CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" - | !{params.CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index - "!{cram}"
    fi    
}

main "$@"
