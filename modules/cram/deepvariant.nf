process deepvariant_call {
  label 'deepvariant_call'

  input:
    tuple val(meta), path(cram), path(cramCrai)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.')) 
    bed="${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    
    vcfOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chunk_${meta.chunk.index}_snv.g.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    platform=meta.project.sequencing_platform == "nanopore" ? "ont" : (meta.project.sequencing_platform == "pacbio_hifi" ? "hifi" : "ilmn")
    modelName=params.snv.clair3[meta.project.sequencing_platform].model_name

    template 'deepvariant_call.sh'

  stub:
    vcfOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chunk_${meta.chunk.index}_snv.g.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"
    
    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}
