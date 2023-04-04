process sniffles2_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(snfOut)
  shell:
    reference = params[meta.sample.assembly].reference.fasta
    tandemRepeatAnnotations = params.cram.sniffles2[meta.sample.assembly].tandem_repeat_annotations
    bed = "${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    snfOut="${meta.sample.individual_id}_${meta.chunk.index}.snf"

    template 'sniffles2_call.sh'
}

process sniffles2_combined_call {
  input:
    tuple val(meta), path(snfs)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    reference = params[meta.assembly].reference.fasta
    tandemRepeatAnnotations = params.cram.sniffles2[meta.assembly].tandem_repeat_annotations
    bed = "${meta.project_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    vcfOut="${meta.project_id}_${meta.chunk.index}_long_read_sv.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"
    
    template 'sniffles2_combined_call.sh'
}

process sniffles_call_publish {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple path(vcfOut), path(vcfOutIndex)
  shell:
    vcfOut="${meta.project_id}_long_read_sv.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    template 'publish.sh'
}