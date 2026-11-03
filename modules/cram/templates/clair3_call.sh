#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

call_small_variants () {
    local args=()
    args+=("--bam_fn" "!{cram}")
    args+=("--ref_fn" "!{reference}")
    args+=("--threads" "!{task.cpus}")
    args+=("--platform" "ont")
    args+=("--model_path" "!{model}")
    args+=("--output" ".")
    args+=("--include_all_ctgs")
    args+=("--gender" "!{sampleSex}")
    if [ -n "!{parRegionsBed}" ]; then
        args+=("--par_regions_bed=!{parRegionsBed}")
    fi
    # workaround for 'default' sample name in output in case sample name can't be derived from CallVariantsOutput or nonvariant site TFRecords
    args+=("--postprocess_variants_extra_args=--sample_name=\"!{sampleName}\"")
    mkdir tmp
    TMPDIR=tmp ${CMD_CLAIR3} "${args[@]}"
}

call_small_variants_cleanup () {
 # rm -rf intermediate_results
 # rm -rf tmp
}

index () {
 # ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
 # ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    trap 'rc=$?; call_small_variants_cleanup; exit $rc' EXIT INT TERM

    create_bed
    call_small_variants
    index
}

main "$@"
