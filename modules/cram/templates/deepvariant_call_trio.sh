#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

call_small_variants () {
    # postprocess extra args
    local postprocess_variants_male_extra_args=()
    if [ -n "!{haploidContigs}" ]; then
      postprocess_variants_male_extra_args+=("--haploid_contigs=\"!{haploidContigs}\"")
    fi
    if [ -n "!{parRegionsBed}" ]; then
      postprocess_variants_male_extra_args+=("--par_regions_bed=\"!{parRegionsBed}\"")
    fi

    # postprocess extra args: child
    # workaround for 'default' sample name in output in case sample name can't be derived from CallVariantsOutput or nonvariant site TFRecords
    local postprocess_variants_child_extra_args="--sample_name=\"!{sampleNameChild}\""
    if [ "!{sampleSex}" = "male" ] && [ "${#postprocess_variants_male_extra_args[@]}" -gt 0 ]; then
      postprocess_variants_child_extra_args+=",$(IFS=,; echo "${postprocess_variants_male_extra_args[*]}")"
    fi

    # postprocess extra args: father
    # workaround for 'default' sample name in output in case sample name can't be derived from CallVariantsOutput or nonvariant site TFRecords
    local postprocess_variants_parent1_extra_args="--sample_name=\"!{sampleNamePaternal}\""
    if [ "${#postprocess_variants_male_extra_args[@]}" -gt 0 ]; then
      postprocess_variants_parent1_extra_args+=",$(IFS=,; echo "${postprocess_variants_male_extra_args[*]}")"
    fi

    # postprocess extra args: mother
    # workaround for 'default' sample name in output in case sample name can't be derived from CallVariantsOutput or nonvariant site TFRecords
    local postprocess_variants_parent2_extra_args="--sample_name=\"!{sampleNameMaternal}\""

    local args=()
    args+=("--model_type" "!{modelType}")
    args+=("--ref" "!{reference}")
    args+=("--reads_child" "!{cramChild}")
    args+=("--reads_parent1" "!{cramPaternal}")
    args+=("--reads_parent2" "!{cramMaternal}")
    args+=("--sample_name_child" "!{sampleNameChild}")
    args+=("--sample_name_parent1" "!{sampleNamePaternal}")
    args+=("--sample_name_parent2" "!{sampleNameMaternal}")
    args+=("--output_gvcf_child" "!{gvcfOutChild}")
    args+=("--output_gvcf_parent1" "!{gvcfOutPaternal}")
    args+=("--output_gvcf_parent2" "!{gvcfOutMaternal}")
    args+=("--num_shards" "!{task.cpus}")
    args+=("--regions" "!{bed}")
    args+=("--intermediate_results_dir" "intermediate_results")
    # required vcf outputs that won't be used
    args+=("--output_vcf_child" "!{vcfOutChild}")
    args+=("--output_vcf_parent1" "!{vcfOutPaternal}")
    args+=("--output_vcf_parent2" "!{vcfOutMaternal}")
    args+=("--make_examples_extra_args=include_med_dp=true")
    args+=("--postprocess_variants_child_extra_args=${postprocess_variants_child_extra_args}")
    args+=("--postprocess_variants_parent1_extra_args=${postprocess_variants_parent1_extra_args}")
    args+=("--postprocess_variants_parent2_extra_args=${postprocess_variants_parent2_extra_args}")
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

  ${CMD_BCFTOOLS} index --csi --output "!{gvcfOutIndexPaternal}" --threads "!{task.cpus}" "!{gvcfOutPaternal}"
  ${CMD_BCFTOOLS} index --stats "!{gvcfOutPaternal}" > "!{gvcfOutStatsPaternal}"

  ${CMD_BCFTOOLS} index --csi --output "!{gvcfOutIndexMaternal}" --threads "!{task.cpus}" "!{gvcfOutMaternal}"
  ${CMD_BCFTOOLS} index --stats "!{gvcfOutMaternal}" > "!{gvcfOutStatsMaternal}"
}

main() {
    trap 'rc=$?; call_small_variants_cleanup; exit $rc' EXIT INT TERM

    create_bed
    call_small_variants
    index
}

main "$@"
