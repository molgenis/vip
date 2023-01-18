process clair3_call {
  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    reference=params[params.assembly].reference.fasta
    bed="${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    // TODO produce .g.vcf instead of .vcf
    vcfOut="${meta.sample.individual_id}_${meta.chunk.index}.vcf.gz"
    vcfOutIndex="${vcfOut}.tbi"
    vcfOutStats="${vcfOut}.stats"

    platform=params.sequencingMethod == "ONT" ? "ont" : "ilmn"
    modelName=params.sequencingMethod == "ONT" ? "r941_prom_sup_g5014" : "ilmn" //TODO make configurable

    template 'clair3_call.sh'
}
