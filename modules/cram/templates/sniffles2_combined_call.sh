#!/bin/bash
set -euo pipefail

call_structural_variants () {
    local args=()
    args+=("--input" !{snfs})
    args+=("--reference" "!{reference}")
    args+=("--tandem-repeats" "!{tandemRepeatAnnotations}")
    args+=("--vcf" "!{vcfOut}")
    args+=("--threads" "!{task.cpus}")

    !{params.CMD_SNIFFLES2} "${args[@]}"
}

stats () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    call_structural_variants
    stats
}

main "$@"