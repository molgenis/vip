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

fixref () {
  # Workaround for https://github.com/tjiangHIT/cuteSV/issues/124
  while IFS=$'\t' read -r -a fields
  do
    if [[ "${fields[0]}" != \#* && "${fields[3]}" == "N" ]]; then
      ref=$(${CMD_SAMTOOLS} faidx "!{reference}" "${fields[0]}:${fields[1]}-${fields[1]}" | sed -n '2 p')
      fields[3]="${ref}"
      length="${#fields[4]}"
      #Fix breakend ALTS
      if [[ "${fields[4]}" == \]* && "${fields[4]}" == *N ]]; then
        fields[4]="${fields[4]:0:(length-1)}${ref}"
      elif [[ "${fields[4]}" == *\[ && "${fields[4]}" == N* ]]; then
        fields[4]="${ref}${fields[4]:1:length}"
      #Fix regular insertion ALT
      elif [[ "${fields[4]}" == N* && "${length}" -gt 1 ]]; then
        fields[4]="${ref}${fields[4]:1:length}"
      fi
    fi
    (IFS=$'\t'; echo "${fields[*]}") >> "fixed_ref_output.vcf"
  done < "cutesv_output.vcf"
}

postprocess () {
    # Workaround for https://github.com/tjiangHIT/cuteSV/issues/124
    cat "fixed_ref_output.vcf" | awk -v FS='\t' -v OFS='\t' '/^[^#]/{gsub(/[YSB]/, "C", $4) gsub(/[WMRDHV]/, "A", $4) gsub("K", "G", $4)} 1' | ${CMD_BCFTOOLS} view --output-type z --output "replaced_IUPAC_cuteSV.vcf.gz" --no-version --threads "!{task.cpus}"
    ${CMD_BCFTOOLS} index --csi --output "replaced_IUPAC_cuteSV.vcf.gz.csi" --threads "!{task.cpus}" "replaced_IUPAC_cuteSV.vcf.gz"
    ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" "replaced_IUPAC_cuteSV.vcf.gz"
    ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
    ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
    rm "replaced_IUPAC_cuteSV.vcf.gz.csi" "replaced_IUPAC_cuteSV.vcf.gz" "fixed_ref_output.vcf" "cutesv_output.vcf"
}

main() {
    call_structural_variants
    fixref
    postprocess
}

main "$@"