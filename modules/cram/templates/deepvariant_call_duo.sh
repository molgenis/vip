#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

call_small_variants () {
    local args=()
    args+=("--model_type" "!{modelType}")
    args+=("--ref" "!{reference}")
    args+=("--reads_child" "!{cramChild}")
    args+=("--reads_parent1" "!{cramParent}")
    args+=("--sample_name_child" "!{sampleNameChild}")
    args+=("--sample_name_parent1" "!{sampleNameParent}")
    args+=("--output_gvcf_child" "!{gvcfOutChild}")
    args+=("--output_gvcf_parent1" "!{gvcfOutParent}")
    args+=("--num_shards" "!{task.cpus}")
    args+=("--regions" "!{bed}")
    args+=("--intermediate_results_dir" "intermediate_results")
    # required vcf outputs that won't be used
    args+=("--output_vcf_child" "!{vcfOutChild}")
    args+=("--output_vcf_parent1" "!{vcfOutParent}")
    args+=("--make_examples_extra_args=\"include_med_dp=true\"")

    mkdir tmp
    TMPDIR=tmp ${CMD_DEEPVARIANT_DEEPTRIO} "${args[@]}"
}

call_small_variants_cleanup () {
  rm -rf intermediate_results
  rm -rf tmp
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{gvcfOutIndexChild}" --threads "!{task.cpus}" "!{gvcfOutChild}"
  ${CMD_BCFTOOLS} index --stats "!{gvcfOutChild}" > "!{gvcfOutStatsChild}"

  ${CMD_BCFTOOLS} index --csi --output "!{gvcfOutIndexParent}" --threads "!{task.cpus}" "!{gvcfOutParent}"
  ${CMD_BCFTOOLS} index --stats "!{gvcfOutParent}" > "!{gvcfOutStatsParent}"
}

main() {
    create_bed
    call_small_variants
    call_small_variants_cleanup
    index
}

main "$@"
