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

    mv "merge_output.vcf.gz" "!{vcfOut}"
    mv "merge_output.vcf.gz.tbi" "!{vcfOutIndex}"
}

stats () {
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    convert_to_bam
    call_small_variants
    stats
}

main "$@"
