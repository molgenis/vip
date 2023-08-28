#!/bin/bash
set -euo pipefail

convert_to_bam () {
  ${CMD_SAMTOOLS} view --reference "!{paramReference}" --bam --output "!{cram}.bam" --threads "!{task.cpus}" "!{cram}"
  ${CMD_SAMTOOLS} index "!{cram}.bam"
}

convert_to_bam_cleanup () {
  rm "!{cram}.bam" "!{cram}.bam.bai"
}

call_short_tandem_repeats () {
    local args=()
    args+=("--loci" "!{paramLoci}")
    args+=("--sample" "!{sampleId}")
    args+=("--vcf" "straglr.vcf")
    if [ -z "!{sampleSex}" ]; then
        args+=("--sex" "!{sampleSex}")
    fi
    args+=("--min_support" "!{paramMinSupport}")
    args+=("--min_cluster_size" "!{paramMinClusterSize}")
    args+=("!{cram}.bam")
    args+=("!{paramReference}")

    ${CMD_STRAGLR} "${args[@]}"
}

index () {
  ${CMD_BGZIP} -c straglr.vcf > !{vcfOut}
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"

  rm straglr.vcf
}

main() {
    convert_to_bam
    call_short_tandem_repeats
    convert_to_bam_cleanup
    index
}

main "$@"