#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

call_small_variants () {
    local args=()
    args+=("--model_type" "!{model}")
    args+=("--ref" "!{reference}")
    args+=("--reads" "!{cram}")
    args+=("--output_vcf" "!{vcfOut}")
    args+=("--num_shards" "!{task.cpus}")
    args+=("--regions" "!{bed}")
    args+=("--intermediate_results_dir" ".")
    args+=("--sample_name" "!{sampleName}")

    ${CMD_DEEPVARIANT} "${args[@]}" 
}

stats () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    call_small_variants
    stats
}

main "$@"
