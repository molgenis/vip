#!/bin/bash
set -euo pipefail

call_short_tandem_repeats () {
    local args=()
    args+=("--loci" "!{paramLoci}")
    args+=("--sample" "!{sampleId}")
    if [ -n "!{sampleSex}" ]; then
        args+=("--sex" "!{sampleSex}")
    fi
    args+=("--min_support" "!{paramMinSupport}")
    args+=("--min_cluster_size" "!{paramMinClusterSize}")
    args+=("!{cram}")
    args+=("!{paramReference}")
    args+=("straglr")

    ${CMD_STRAGLR} "${args[@]}"

    mv straglr.tsv "!{tsvOut}"
    rm straglr.vcf
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

tsv2vcf() {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toMega() - 512}m")
  args+=("-jar" "/opt/straglr-tsv2vcf/lib/straglrTsv2Vcf.jar")
  args+=("--input" ""!{tsvOut}")
  args+=("--loci" "!{paramLoci}")
  args+=("--reference" "!{paramReference}")
  if [ "!{sampleSex}" == "male" ]; then
    args+=("--haploid_contigs" "!{haploidContigsMale}")
  fi
  args+=("--sample" "!{sampleId}")
  args+=("--output" "!{vcfOut}")

  ${CMD_STRAGLR_TSV2VCF} java "${args[@]}"
}

main() {
    call_short_tandem_repeats
    tsv2vcf
    index
}

main "$@"