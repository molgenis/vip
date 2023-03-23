#!/bin/bash
set -euo pipefail

call_structural_variants () {
    local args=()
    args+=("--input" !{snfs})
    args+=("--reference" "!{reference}")
    args+=("--tandem-repeats" "!{tandemRepeatAnnotations}")
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
    call_structural_variants
    stats
}

main "$@"