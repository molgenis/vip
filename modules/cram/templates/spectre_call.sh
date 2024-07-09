#!/bin/bash
set -euo pipefail

mosdepth () {
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
    if [ "!{sampleSex}" == "male" ]; then
        args+=("--ploidy-chr" "chrX:1,chrY:1")
    else
        args+=("--ploidy-chr" "chrX:2")
    fi
                    
    ${CMD_SPECTRE} "${args[@]}"
}


index () {
# empty result of spectre results in an extra empty line.
  if [ -z "$(tail -n 1 ./spectre/HG002.vcf)" ]; then
    sed -i '$ d' "spectre/!{sampleId}.vcf"
  fi
  ${CMD_BGZIP} -c "spectre/!{sampleId}.vcf" > "!{vcfOut}"
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}


main() {
    mosdepth
    call_copy_number_variation
    index
}

main "$@"