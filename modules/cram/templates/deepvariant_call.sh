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
    args+=("--intermediate_results_dir" "intermediate_results")
    args+=("--sample_name" "!{sampleName}")
    args+=("--make_examples_extra_args=include_med_dp=true")
    if [ "!{sampleSex}" = "male"  ]; then
      if [ -n "!{haploidContigs}" ]; then
        args+=("--haploid_contigs=!{haploidContigs}")
      fi
      if [ -n "!{parRegionsBed}" ]; then
        args+=("--par_regions_bed=!{parRegionsBed}")
      fi
    fi
    # workaround for 'default' sample name in output in case sample name can't be derived from CallVariantsOutput or nonvariant site TFRecords
    args+=("--postprocess_variants_extra_args=--sample_name=\"!{sampleName}\"")
    mkdir tmp
    TMPDIR=tmp ${CMD_DEEPVARIANT} "${args[@]}"
}

call_small_variants_cleanup () {
  rm -rf intermediate_results
  rm -rf tmp
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    trap 'rc=$?; call_small_variants_cleanup; exit $rc' EXIT INT TERM

    create_bed
    call_small_variants
    index
}

main "$@"
