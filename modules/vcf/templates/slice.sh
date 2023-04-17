#!/bin/bash
set -euo pipefail

create_bed () {
    local args=()
    args+=("view")
    args+=("--no-header")
    args+=("--no-version")
    args+=("--threads" "!{task.cpus}")
    args+=("!{vcf}")
    
    # -1 because positions in .bed are 0-based and 1-based in .vcf
    !{params.CMD_BCFTOOLS} "${args[@]}" | awk -v FS='\t' -v OFS='\t' '{print $1 "\t" $2-1 "\t" $2-1 "\t"}' > "!{vcf.simpleName}.bed"
}

slice () {
    local args=()
    args+=("view")
    args+=("--cram")
    args+=("--output" "!{cramOut}")
    args+=("--target-file" "!{vcf.simpleName}.bed")
    args+=("--reference" "!{refSeqPath}")
    args+=("--output-fmt-option" "level=9")
    args+=("--output-fmt-option" "archive")
    # not supported by igv.js v2.13.3
    args+=("--output-fmt-option" "use_lzma=0")
    # not supported by igv.js v2.13.3
    args+=("--output-fmt-option" "use_bzip2=0")
    args+=("--write-index")
    args+=("--no-PG")
    args+=("--threads" "!{task.cpus}")
    args+=("!{cram}")

    !{params.CMD_SAMTOOLS} "${args[@]}"
}

main() {
    create_bed
    slice
}

main "$@"
