#!/bin/bash
set -euo pipefail

mosdepth () {
    local args=()
    args+=("--coverage" "mosdepth/sampleid/mosdepth.regions.bed.gz")
    args+=("--threads"  "!{task.cpus}")
    args+=("--by" "1000")
    args+=("--fasta" "!{paramReference}")
    args+=("--chrom" "X") //TODO: chromosome to restrict depth calculation.
    args+=("--mapq" "20")
    args+=("--fast-mode")
    args+=("mosdespth")
    args+=("!{cram}")

                
    ${CMD_MOSDEPTH} "${args[@]}"
}

call_copy_number_variation () {
    local args=()
    args+=("--coverage mosdepth/mosdepth.regions.bed.gz")
    args+=("--sample-id" "!{sampleName}")
    args+=("--output-dir" "spectre")
    args+=("--reference" "!{paramReference}")
    if [ "!{sampleSex}" == "male" ]; then
        args+=("--ploidy-chr" "chrX:1,chrY:1")
    else
        args+=("--ploidy-chr" "chrX:2")
    fi
    args+=("--snv", "snvVcf")
                
    ${CMD_SPECTRE} "${args[@]}"
}

split_vcf () {
    #TODO single sample VCF
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    split_vcf
    mosdepth
    call_copy_number_variation
    index
}

main "$@"