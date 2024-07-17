#!/bin/bash
set -euo pipefail

mosdepth () {
    # Spectre recommends running Mosdepth with a bin size of 1kb and a mapping quality of at least 20
    local args=()
    args+=("--threads"  "!{task.cpus}")
    args+=("--by" "1000")
    args+=("--fasta" "!{paramReference}")
    args+=("--mapq" "20")
    args+=("--fast-mode")
    args+=("mosdepth")
    args+=("!{cram}")
    ${CMD_MOSDEPTH} "${args[@]}"
}

call_copy_number_variation () {
    local args=()
    args+=("CNVCaller")
    args+=("--coverage" "mosdepth.regions.bed.gz")
    args+=("--sample-id" "!{sampleId}")
    args+=("--output-dir" "spectre")
    args+=("--reference" "!{paramReference}")
    args+=("--metadata" "!{paramMetadata}")
    args+=("--blacklist" "!{paramBlacklist}")
    args+=("--threads" "!{task.cpus}")
    if [ "!{sampleSex}" == "male" ]; then
        args+=("--ploidy-chr" "chrX:1,chrY:1")
    else
        args+=("--ploidy-chr" "chrX:2")
    fi

    ${CMD_SPECTRE} "${args[@]}"

    mv "./spectre/!{sampleId}.vcf.gz" "!{vcfOut}"
}

index () {
    ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
    ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    mosdepth
    call_copy_number_variation
    index
}

main "$@"
