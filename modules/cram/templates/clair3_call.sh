#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

# workaround for clair 3 issue where the ebi server is called to decode the cram
# https://github.com/HKU-BAL/Clair3/issues/180
convert_to_bam () {
  ${CMD_SAMTOOLS} view --reference "!{reference}" --bam --regions-file "!{bed}" --output "!{cram}.bam" --threads "1" "!{cram}"
  ${CMD_SAMTOOLS} index "!{cram}.bam"
}

convert_to_bam_cleanup () {
  rm "!{cram}.bam" "!{cram}.bam.bai"
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
    args+=("--remove_intermediate_dir")
    args+=("--gvcf")

    # Prevent Clair3 writing in home directory via samtools (https://www.htslib.org/doc/samtools.html#ENVIRONMENT_VARIABLES)
    XDG_CACHE_HOME=$(realpath .) ${CMD_CLAIR3} "${args[@]}"

    mv "merge_output.gvcf.gz" "!{vcfOut}"
    mv "merge_output.gvcf.gz.tbi" "!{vcfOutIndex}"
}

stats () {
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

#To exit with error when https://github.com/HKU-BAL/Clair3/issues/200 occurs, otherwise it will fail in the next steps of the pipeline without possibility of the "retry stategy".
validate () {
  ${CMD_BCFTOOLS} view "!{vcfOut}" > /dev/null
}

main() {
    create_bed
    convert_to_bam
    call_small_variants
    convert_to_bam_cleanup
    validate
    stats
}

main "$@"
