process clair3_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    refSeqPath = params[params.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.')) 
    bed="${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    vcfOut="${meta.sample.individual_id}_${meta.chunk.index}.vcf.gz"
    vcfOutIndex="${vcfOut}.tbi"
    vcfOutStats="${vcfOut}.stats"

    platform=params.sequencingMethod == "ONT" ? "ont" : "ilmn"
    modelName=params.cram.clair3[params.sequencingMethod].model_name

    template 'clair3_call.sh'
}