#!/bin/bash
set -euo pipefail

create_bed () {
    local args=()
    args+=("query")
    args+=("-f" "%CHROM\t%POS\n")
    args+=("!{vcf}")
    
    # -1 because positions in .bed are 0-based and 1-based in .vcf
    ${CMD_BCFTOOLS} "${args[@]}" | awk '{ start = ($2 - 100001 < 0) ? 0 : $2 - 100001;end = $2 + 100000;print $1"\t"start"\t"end;}' >  "!{vcf.simpleName}.bed"
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

    ${CMD_SAMTOOLS} "${args[@]}"
}

main() {
    create_bed
    slice
}

main "$@"
