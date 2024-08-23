#!/bin/bash
set -euo pipefail

call_short_tandem_repeats () {
    local args=()
    args+=("--loci" "!{paramLoci}")
    args+=("--sample" "!{sampleId}")
    if [ -z "!{sampleSex}" ]; then
        args+=("--sex" "!{sampleSex}")
    fi
    args+=("--min_support" "!{paramMinSupport}")
    args+=("--min_cluster_size" "!{paramMinClusterSize}")
    args+=("!{cram}")
    args+=("!{paramReference}")
    args+=("straglr")

    ${CMD_STRAGLR} "${args[@]}"

    mv straglr.tsv "!{tsvOut}"
}

index () {
  awk '/#CHROM*/{print "##INFO=<ID=SVTYPE,Number=1,Type=String,Description=\"Type of structural variant\">"}1' ./straglr.vcf |\
  awk 'BEGIN{FS=OFS="\t"} /^#/ {print; next} {$8="SVTYPE=STR;"$8; print; next;} { print; }'h > straglr_headered.vcf
  ${CMD_BCFTOOLS} reheader --fai "!{paramReferenceFai}" --temp-prefix . --threads "!{task.cpus}" straglr_headered.vcf |\
  ${CMD_BCFTOOLS} sort --temp-dir . --max-mem "!{task.memory.toGiga() - 1}G" --output-type z --output "!{vcfOut}"

  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"

  rm straglr.vcf
  rm straglr_headered.vcf
}

main() {
    call_short_tandem_repeats
    index
}

main "$@"