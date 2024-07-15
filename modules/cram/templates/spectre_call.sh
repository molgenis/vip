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

postprocess() {
    # empty result of spectre is a vcf file and not a vcf.gz. https://github.com/fritzsedlazeck/Spectre/issues/26
    if [ -f "./spectre/!{sampleId}.vcf" ]; then
      # empty result of spectre results in an extra empty line. https://github.com/fritzsedlazeck/Spectre/issues/26
      # Fix illegal DP FORMAT field in Spectre output https://github.com/fritzsedlazeck/Spectre/issues/27
      sed -i '$ d' "spectre/!{sampleId}.vcf" |\
      sed "s/##FORMAT=<ID=DP,Number=2,Type=Float,Description=\"Read depth\">/##FORMAT=<ID=DPS,Number=1,Type=Float,Description=\"Spectre read depth\">/g" |\
      sed "s/:DP/:DPS/g" |\
      ${CMD_BGZIP} -c > "!{vcfOut}"
    else
      zcat "./spectre/!{sampleId}.vcf.gz" |\
      # Fix illegal DP FORMAT field in Spectre output https://github.com/fritzsedlazeck/Spectre/issues/27
      sed "s/##FORMAT=<ID=DP,Number=2,Type=Float,Description=\"Read depth\">/##FORMAT=<ID=DPS,Number=1,Type=Float,Description=\"Spectre read depth\">/g" |\
      sed "s/:DP/:DPS/g" |\
      ${CMD_BGZIP} -c > "!{vcfOut}"
    fi
}

index () {
    ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
    ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    mosdepth
    call_copy_number_variation
	  postprocess
    index
}

main "$@"
