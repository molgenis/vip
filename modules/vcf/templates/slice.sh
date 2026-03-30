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
    ${CMD_BCFTOOLS} "${args[@]}" | awk -v FS='\t' -v OFS='\t' '{print $1 "\t" $2-1 "\t" $2 "\t"}' > "!{vcf.simpleName}.bed"
}

slice_and_strip () {
    local slice_args=()
    slice_args+=("view")
    slice_args+=("--with-header")
    slice_args+=("--threads" "!{task.cpus}")
    slice_args+=("--target-file" "!{vcf.simpleName}.bed")
    slice_args+=("--reference" "!{refSeqPath}")
    slice_args+=("--no-PG")
    slice_args+=("!{cram}")

    local strip_args=()
    strip_args+=("view")
    strip_args+=("--cram")
    strip_args+=("--output" "!{cramOut}")
    strip_args+=("--reference" "!{refSeqPath}")
    strip_args+=("--output-fmt-option" "level=9")
    strip_args+=("--output-fmt-option" "archive")
    # not supported by igv.js v2.13.3
    strip_args+=("--output-fmt-option" "use_lzma=0")
    # not supported by igv.js v2.13.3
    strip_args+=("--output-fmt-option" "use_bzip2=0")
    strip_args+=("--write-index")
    strip_args+=("--no-PG")
    strip_args+=("--threads" "!{task.cpus}")

    ${CMD_SAMTOOLS} "${slice_args[@]}" | \
    awk -v FS='\t' -v OFS='\t' '
      /^@/ {print; next}
      {
          # drop QUAL
          $11="*"

          # print core SAM fields
          printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s",
                 $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11

          print ""
      }' | \
    ${CMD_SAMTOOLS} "${strip_args[@]}"
}

main() {
    create_bed
    slice_and_strip
}

main "$@"
