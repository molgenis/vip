#!/bin/bash
set -euo pipefail

main() {
    IFS=' ' read -a cram_array <<< "!{crams}";
    if [ ${#cram_array} -gt 1 ]
    then
        ${CMD_SAMTOOLS} merge -@ "!{task.cpus}" -o !{cramOut} --write-index "${cram_array}"
    else
        mv !{crams} "!{cramOut}"
        exit 2
    fi

    if [ "!{isPairEnded}" == "true"]
    then
        ${CMD_SAMTOOLS} fixmate -u -m - - | \
        ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" - | \
        ${CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index - "!{cramOut}"
    else
        ${CMD_SAMTOOLS} index "!{cramOut}"
    fi
    ${CMD_SAMTOOLS} idxstats "!{cramOut}" > "!{cramOutStats}"
}

main "$@"
