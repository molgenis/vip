#!/bin/bash
set -euo pipefail

# workaround for cutesv
convert_to_bam () {
  echo -e "!{bedContent}" > "!{bed}"
  ${CMD_SAMTOOLS} view --reference "!{reference}" --bam --regions-file "!{bed}" --output "!{cram}.bam" --threads "!{task.cpus}" "!{cram}"
  ${CMD_SAMTOOLS} index "!{cram}.bam"
}

convert_to_bam_cleanup () {
  rm "!{cram}.bam" "!{cram}.bam.bai"
}

call_structural_variants () {
    local args=()
    args+=("--sample" "!{sampleId}")
    args+=("--genotype")

    if [[ "!{sequencingPlatform}" == "nanopore" ]]; then
      args+=("--max_cluster_bias_INS" "100")
      args+=("--diff_ratio_merging_INS" "0.3")
      args+=("--max_cluster_bias_DEL" "100")
      args+=("--diff_ratio_merging_DEL" "0.3")
    elif [[ "!{sequencingPlatform}" == "pacbio_hifi" ]]; then
      args+=("--max_cluster_bias_INS" "1000")
      args+=("--diff_ratio_merging_INS" "0.9")
      args+=("--max_cluster_bias_DEL" "1000")
      args+=("--diff_ratio_merging_DEL" "0.5")
    fi

    args+=("--threads" "!{task.cpus}")
    args+=("!{cram}.bam")
    args+=("!{reference}")
    args+=("cutesv_output.vcf")
    args+=(".")

    ${CMD_CUTESV} "${args[@]}"
}

postprocess () {
  ${CMD_BCFTOOLS} view --output-type z --output "unfiltered_!{vcfOut}" --no-version --threads "!{task.cpus}" "cutesv_output.vcf"
  ${CMD_BCFTOOLS} index --csi --output "unfiltered_!{vcfOutIndex}" --threads "!{task.cpus}" "unfiltered_!{vcfOut}"
  ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --regions-file "!{bed}" --no-version --threads "!{task.cpus}" "unfiltered_!{vcfOut}"
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
  rm "unfiltered_!{vcfOutIndex}" "unfiltered_!{vcfOut}"
}

main() {
    convert_to_bam
    call_structural_variants
    convert_to_bam_cleanup

    postprocess
}

main "$@"