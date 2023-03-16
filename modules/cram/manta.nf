process manta_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    refSeqPath = params[meta.sample.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.')) 
    bed="${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedGz="${bed}.gz"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    sequencingMethod = meta.sample.sequencing_method

    vcfOut="${meta.sample.individual_id}_${meta.chunk.index}_sv.vcf.gz"
    vcfOutIndex="${vcfOut}.tbi"
    vcfOutStats="${vcfOut}.stats"

    template 'manta_call.sh'
}

process manta_call_publish {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)
  shell:
    vcfOut="${meta.sample.project_id}_${meta.sample.family_id}_${meta.sample.individual_id}_sv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'publish.sh'
}