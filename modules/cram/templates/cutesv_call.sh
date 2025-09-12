#!/bin/bash
set -euo pipefail

call_structural_variants () {
  #usage: cuteSV [-h] [--version] [-t THREADS] [-b BATCHES] [-S SAMPLE] [--retain_work_dir] [--write_old_sigs] [--report_readid] [-p MAX_SPLIT_PARTS] [-q MIN_MAPQ] [-r MIN_READ_LEN] [-md MERGE_DEL_THRESHOLD]
  #              [-mi MERGE_INS_THRESHOLD] [-include_bed INCLUDE_BED] [-s MIN_SUPPORT] [-l MIN_SIZE] [-L MAX_SIZE] [-sl MIN_SIGLENGTH] [--genotype] [--gt_round GT_ROUND] [--read_range READ_RANGE] [-Ivcf IVCF]
  #              [--max_cluster_bias_INS MAX_CLUSTER_BIAS_INS] [--diff_ratio_merging_INS DIFF_RATIO_MERGING_INS] [--max_cluster_bias_DEL MAX_CLUSTER_BIAS_DEL] [--diff_ratio_merging_DEL DIFF_RATIO_MERGING_DEL]
  #              [--max_cluster_bias_INV MAX_CLUSTER_BIAS_INV] [--max_cluster_bias_DUP MAX_CLUSTER_BIAS_DUP] [--max_cluster_bias_TRA MAX_CLUSTER_BIAS_TRA] [--diff_ratio_filtering_TRA DIFF_RATIO_FILTERING_TRA]
  #              [--remain_reads_ratio REMAIN_READS_RATIO]
  #              [BAM] reference output work_dir
  local args=()
  args+=("--threads" "!{task.cpus}")
  args+=("--batches" "!{paramBatches}")
  args+=("--sample" "!{sampleId}")
  if [[ "!{paramRetainWorkDir}" == "true" ]]; then
    args+=("--retain_work_dir")
  fi
  if [[ "!{paramWriteOldSigs}" == "true" ]]; then
    args+=("--write_old_sigs")
  fi
  if [[ "!{paramReportReadid}" == "true" ]]; then
    args+=("--report_readid")
  fi
  args+=("--max_split_parts" "!{paramMaxSplitParts}")
  args+=("--min_mapq" "!{paramMinMapq}")
  args+=("--min_read_len" "!{paramMinReadLen}")
  args+=("--merge_del_threshold" "!{paramMergeDelThreshold}")
  args+=("--merge_ins_threshold" "!{paramMergeInsThreshold}")
  if [[ -n "!{paramIncludeBed}" ]]; then
    args+=("-include_bed" "!{paramIncludeBed}") # note: '-' instead of '--'
  fi
  args+=("--min_support" "!{paramMinSupport}")
  args+=("--min_size" "!{paramMinSize}")
  args+=("--max_size" "!{paramMaxSize}")
  args+=("--min_siglength" "!{paramMinSiglength}")
  args+=("--genotype")
  args+=("--gt_round" "!{paramGtRound}")
  args+=("--read_range" "!{paramReadRange}")
  if [[ -n "!{paramIvcf}" ]]; then
    args+=("-Ivcf" "!{paramIvcf}") # note: '-' instead of '--'
  fi
  args+=("--max_cluster_bias_INS" "!{paramMaxClusterBiasIns}")
  args+=("--diff_ratio_merging_INS" "!{paramDiffRatioMergingIns}")
  args+=("--max_cluster_bias_DEL" "!{paramMaxClusterBiasDel}")
  args+=("--diff_ratio_merging_DEL" "!{paramDiffRatioMergingDel}")
  args+=("--max_cluster_bias_INV" "!{paramMaxClusterBiasInv}")
  args+=("--max_cluster_bias_DUP" "!{paramMaxClusterBiasDup}")
  args+=("--max_cluster_bias_TRA" "!{paramMaxClusterBiasTra}")
  args+=("--diff_ratio_filtering_TRA" "!{paramDiffRatioFilteringTra}")
  args+=("--remain_reads_ratio" "!{paramRemainReadsRatio}")
  args+=("!{cram}")
  args+=("!{reference}")
  args+=("cutesv_output.vcf")
  args+=(".")

  ${CMD_CUTESV} "${args[@]}"
}

call_structural_variants_postprocess () {
    ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" "cutesv_output.vcf"
    ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
    ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

call_structural_variants_cleanup () {
    rm "cutesv_output.vcf"
}

main() {
    call_structural_variants
    call_structural_variants_postprocess
    call_structural_variants_cleanup
}

main "$@"