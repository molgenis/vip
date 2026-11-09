#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

call_small_variants () {
    local args=()
    args+=("--bam_fn" "!{cram}")
    args+=("--bed_fn" "!{bed}")
    args+=("--ref_fn" "!{reference}")
    args+=("--threads" "!{task.cpus}")
    args+=("--platform" "ont")
    args+=("--model_path" "!{model}")
    args+=("--output" ".")
    args+=("--include_all_ctgs")
    args+=("--sample_name" "!{sampleName}")
    args+=("--gvcf")
    if [ -n "!{sampleSex}" ] && [ "!{sampleSex}" != "null" ]; then
        args+=("--gender" "!{sampleSex}")
    else
        args+=("--gender" "unknown")
    fi
    if [ -n "!{parRegionsBed}" ]; then
        args+=("--par_regions_bed=!{parRegionsBed}")
    fi
    mkdir tmp
    TMPDIR=tmp ${CMD_CLAIR3} "${args[@]}"
    
    mv merge_output.gvcf.gz !{vcfOut}
}

call_small_variants_cleanup () {
  rm merge_output.gvcf.gz
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
