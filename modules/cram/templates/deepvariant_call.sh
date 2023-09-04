#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

call_small_variants () {
    local args=()
    args+=("--model_type" "PACBIO")
    args+=("--ref" "reference/GRCh38_no_alt_analysis_set.fasta")
    args+=("--reads" "input/HG003.GRCh38.chr20.pFDA_truthv2.bam")
    args+=("--output_vcf" "!{vcfOut}")
    args+=("--num_shards" "!{task.cpus}")
    args+=("--regions" "chr20")

    ${CMD_DEEPVARIANT} "${args[@]}"  

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
    call_small_variants
    validate
    stats
}

main "$@"
