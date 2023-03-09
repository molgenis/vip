#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

convert_to_bam () {
  ${CMD_SAMTOOLS} view -T "!{reference}" -b -o !{cram}.bam !{cram}
  ${CMD_SAMTOOLS} index "!{cram}.bam"
}

call_small_variants () {
    local args=()
    args+=("--bam_fn=!{cram}.bam")
    args+=("--ref_fn=$(realpath "!{reference}")")
    args+=("--bed_fn=$(realpath "!{bed}")")
    args+=("--threads=!{task.cpus}")
    args+=("--platform=!{platform}")
    args+=("--model_path=/opt/models/!{modelName}")
    args+=("--output=$(realpath .)")
    args+=("--sample_name=!{meta.sample.individual_id}")
    args+=("--longphase_for_phasing")

    # Prevent Clair3 writing in home directory via samtools (https://www.htslib.org/doc/samtools.html#ENVIRONMENT_VARIABLES)
    XDG_CACHE_HOME=$(realpath .) ${CMD_CLAIR3} "${args[@]}"

    # Workaround for https://github.com/HKU-BAL/Clair3/issues/153
    zcat "merge_output.vcf.gz" | awk -v FS='\t' -v OFS='\t' '/^[^#]/{sub(/[RYSWKMBDHV]/, "N", $4) sub(/[RYSWKMBDHV]/, "N", $5)} 1' | ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    convert_to_bam
    call_small_variants
    index
}

main "$@"
