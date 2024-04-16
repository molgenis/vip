process cutesv_call {
  label 'cutesv_call'
  
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    sampleId = "${meta.sample.individual_id}"

    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    sequencingPlatform = meta.project.sequencing_platform

		// params: sequencing platform independent
		paramBatches = params.sv.cutesv.batches
		paramRetainWorkDir = params.sv.cutesv.retain_work_dir
		paramWriteOldSigs = params.sv.cutesv.write_old_sigs
		paramReportReadid = params.sv.cutesv.report_readid
		paramIncludeBed = params.sv.cutesv.include_bed
		paramIvcf = params.sv.cutesv.ivcf
		paramMaxSplitParts = params.sv.cutesv.max_split_parts
		paramMinMapq = params.sv.cutesv.min_mapq
		paramMinReadLen = params.sv.cutesv.min_read_len
		paramMergeDelThreshold = params.sv.cutesv.merge_del_threshold
		paramMergeInsThreshold = params.sv.cutesv.merge_ins_threshold
		paramMinSupport = params.sv.cutesv.min_support
		paramMinSize = params.sv.cutesv.min_size
		paramMaxSize = params.sv.cutesv.max_size
		paramMinSiglength = params.sv.cutesv.min_siglength
		paramGtRound = params.sv.cutesv.gt_round
		paramReadRange = params.sv.cutesv.read_range

		// params: sequencing platform dependent
		paramMaxClusterBiasIns = params.sv.cutesv[sequencingPlatform].max_cluster_bias_INS
		paramDiffRatioMergingIns = params.sv.cutesv[sequencingPlatform].diff_ratio_merging_INS
		paramMaxClusterBiasDel = params.sv.cutesv[sequencingPlatform].max_cluster_bias_DEL
		paramDiffRatioMergingDel = params.sv.cutesv[sequencingPlatform].diff_ratio_merging_DEL
    paramMaxClusterBiasInv = params.sv.cutesv[sequencingPlatform].max_cluster_bias_INV
    paramMaxClusterBiasDup = params.sv.cutesv[sequencingPlatform].max_cluster_bias_DUP
    paramMaxClusterBiasTra = params.sv.cutesv[sequencingPlatform].max_cluster_bias_TRA
    paramDiffRatioFilteringTra = params.sv.cutesv[sequencingPlatform].diff_ratio_filtering_TRA
		paramRemainReadsRatio = params.sv.cutesv[sequencingPlatform].remain_reads_ratio

    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_sv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'cutesv_call.sh'
  
  stub:
    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_sv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}
