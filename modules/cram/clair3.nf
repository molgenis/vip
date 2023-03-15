process clair3_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    refSeqPath = params[meta.sample.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.')) 
    bed="${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    vcfOut="${meta.sample.individual_id}_${meta.chunk.index}.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    platform=meta.sample.sequencing_platform == "nanopore" ? "ont" : "ilmn"
    modelName=params.cram.clair3[meta.sample.sequencing_platform].model_name

    template 'clair3_call.sh'
}

process clair3_call_publish {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)
  shell:
    vcfOut="${meta.sample.project_id}_${meta.sample.family_id}_${meta.sample.individual_id}_small_variants.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'publish.sh'
}