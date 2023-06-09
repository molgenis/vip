process cutesv_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    bed = "${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    sampleId = "${meta.sample.individual_id}"

    refSeqPath = params[meta.sample.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    sequencingPlatform = meta.sample.sequencing_platform

    vcfOut = "${meta.sample.individual_id}_${meta.chunk.index}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'cutesv_call.sh'
}

process cutesv_merge {
  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    vcfOut = (meta.chunk && meta.chunk.total > 1 ? "${meta.project_id}_chunk_${meta.chunk.index}" : meta.project_id) + "_cutesv_merged.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'cutesv_merge.sh'
}

process cutesv_call_publish {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple path(vcfOut), path(vcfOutIndex)
  shell:
    vcfOut="${meta.sample.project_id}_${meta.sample.family_id}_${meta.sample.individual_id}_sv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'publish.sh'
}