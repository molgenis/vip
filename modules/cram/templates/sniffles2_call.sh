#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

# workaround for https://github.com/fritzsedlazeck/Sniffles/issues/373
create_cram_slice () {
  local args=()
  args+=("view")
  args+=("--cram")
  args+=("--output" "!{cram.simpleName}_sliced.cram")
  args+=("--target-file" "!{bed}")
  args+=("--reference" "!{reference}")
  args+=("--write-index")
  args+=("--no-PG")
  args+=("--threads" "!{task.cpus}")
  args+=("!{cram}")

  ${CMD_SAMTOOLS} "${args[@]}"
}

call_structural_variants () {
    local args=()
    args+=("--input" "!{cram.simpleName}_sliced.cram")
    args+=("--reference" "!{reference}")
    args+=("--tandem-repeats" "!{tandemRepeatAnnotations}")
    #Currently there is no gvcf support in Sniffles: https://github.com/fritzsedlazeck/Sniffles/issues/385
    args+=("--vcf" "!{vcfOut}")
    args+=("--sample-id" "!{meta.sample.individual_id}")
    args+=("--threads" "!{task.cpus}")

    ${CMD_SNIFFLES2} "${args[@]}"
}

stats () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    create_cram_slice
    call_structural_variants
    stats
}

main "$@"