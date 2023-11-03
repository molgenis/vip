#!/bin/bash
set -euo pipefail

merge(){
    IFS=' ' read -a cram_array <<< "!{crams}";
    if [ ${#cram_array} -gt 1 ]
    then
        ${CMD_SAMTOOLS} merge -@ "!{task.cpus}" -o "unmarked_!{cramOut}" --write-index !{crams}
    else
        # include single crams in the merge process to include them in the publish
        cp !{crams} "unmarked_!{cramOut}"
    fi
}

mark_dups(){
    if [ "!{isPairEnded}" == "true" ]
    then
        #name sort for fixmate
        ${CMD_SAMTOOLS} sort -n -@ "!{task.cpus}" -o - "unmarked_!{cramOut}" | \
        ${CMD_SAMTOOLS} fixmate -u -m -@ "!{task.cpus}" - - | \
        #position sort for markdup
        ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" - | \
        ${CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index - "!{cramOut}"
    else
        if [[ "!{platform}" == "nanopore" ]]; then
            ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" --reference "!{reference}" -o "!{cramOut}" --write-index "unmarked_!{cramOut}"
        else
            ${CMD_SAMTOOLS} sort -u -@ "!{task.cpus}" "unmarked_!{cramOut}" | \
            ${CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index - "!{cramOut}"
        fi
    fi

    ${CMD_SAMTOOLS} idxstats "!{cramOut}" > "!{cramOutStats}"
}

cleanup(){
    rm unmarked_!{cramOut}
}

main() {
    merge
    mark_dups
    cleanup
}

main "$@"
