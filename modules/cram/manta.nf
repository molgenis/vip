process manta_call {
  input:
    tuple val(meta), path(crams), path(cramCrais)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    refSeqPath = params[meta.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.')) 
    bed="${meta.project_id}_${meta.chunk.index}.bed"
    bedGz="${bed}.gz"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    sequencingMethod = meta.samples[0].sample.sequencing_method

    vcfOut="${meta.project_id}_${meta.chunk.index}_sv.vcf.gz"
    vcfOutIndex="${vcfOut}.tbi"
    vcfOutStats="${vcfOut}.stats"

    template 'manta_call.sh'
}

process manta_call_publish {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple path(vcfOut), path(vcfOutIndex)
  shell:
    vcfOut="${meta.project_id}_sv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'publish.sh'
}