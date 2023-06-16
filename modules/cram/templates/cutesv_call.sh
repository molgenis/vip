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
  # Workaround for https://github.com/tjiangHIT/cuteSV/issues/124
  cat "cutesv_output.vcf" | awk -v FS='\t' -v OFS='\t' '/^[^#]/{gsub(/[YSB]/, "C", $4) gsub(/[WMRDHV]/, "A", $4) gsub("K", "G", $4)} 1' | ${CMD_BCFTOOLS} view --output-type z --output "replaced_IUPAC_cuteSV.vcf.gz" --no-version --threads "!{task.cpus}"
  ${CMD_BCFTOOLS} index --csi --output "replaced_IUPAC_cuteSV.vcf.gz.csi" --threads "!{task.cpus}" "replaced_IUPAC_cuteSV.vcf.gz"
  ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --regions-file "!{bed}" --no-version --threads "!{task.cpus}" "replaced_IUPAC_cuteSV.vcf.gz"
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
  rm "replaced_IUPAC_cuteSV.vcf.gz.csi" "replaced_IUPAC_cuteSV.vcf.gz"
}

main() {
    convert_to_bam
    call_structural_variants
    convert_to_bam_cleanup

    postprocess
}

main "$@"