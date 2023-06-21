process call {
  label 'clair3_call'

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

    template 'clair3_call.sh'

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

process concat {
  label 'clair3_concat'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_snv.g.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'clair3_call_concat.sh'
  
  stub:
    vcfOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_snv.g.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}

process joint_call {
  label 'clair3_joint_call'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(gVcfs), path(gVcfIndexes)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut="${meta.project.id}_snv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    refSeqFaiPath = params[meta.project.assembly].reference.fastaFai
    config="gatk_unfiltered"

    template 'clair3_joint_call.sh'
    
  stub:
    vcfOut="${meta.project.id}_snv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}