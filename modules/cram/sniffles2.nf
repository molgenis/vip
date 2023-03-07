process sniffles2_sv_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    reference = params[params.assembly].reference.fasta
    tandemRepeatAnnotations = params.cram.sniffles2[params.assembly].tandem_repeat_annotations
    bed = "${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    vcfOut="${meta.sample.individual_id}_${meta.chunk.index}.vcf.gz"
    vcfOutIndex="${vcfOut}.tbi"
    vcfOutStats = "${vcfOut}.stats"

    template 'sniffles2_sv_call.sh'
}