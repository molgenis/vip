#!/bin/bash
set -euo pipefail

merge(){
    IFS=' ' read -a cram_array <<< "!{crams}";
    if [ ${#cram_array} -gt 1 ]
    then
        for cram in "${cram_array[@]}"
        do
            echo "$cram" >> crams.txt
        done
        ${CMD_SAMTOOLS} merge -@ "!{task.cpus}" -o "!{cramOut}" -b crams.txt --write-index
    fi
}

mark_dups(){
    if [[ "!{platform}" != "nanopore" ]]
    then
        mv "!{cramOut}" "unmarked_!{cramOut}"
        ${CMD_SAMTOOLS} markdup -@ "!{task.cpus}" --reference "!{reference}" --write-index "unmarked_!{cramOut}" "!{cramOut}"
    fi

    ${CMD_SAMTOOLS} idxstats "!{cramOut}" > "!{cramOutStats}"
}

cleanup(){
    if [[ "!{platform}" != "nanopore" ]]
    then
        rm unmarked_!{cramOut}
    fi
}

main() {
    merge
    mark_dups
    cleanup
}

main "$@"
