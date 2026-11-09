process call {
  label 'clair3_call'

  input:
    tuple val(meta), path(cram), path(cramCrai)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    haploidContigs = params.snv[meta.project.assembly].reference.haploidContigs
    parRegionsBed = params.snv[meta.project.assembly].reference.parRegionsBed
    chrmName = params.mt[meta.project.assembly].chrm_name
    bed="regions_chunk_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.findAll{ region -> "${region.chrom}" != "${chrmName}" }.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    sampleName = "${meta.sample.individual_id}"
    sampleSex = "${meta.sample.sex}"

    vcfOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chunk_${meta.chunk.index}_snv.g.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    model=params.snv.clair3.model

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

process concat_gvcfs {
  label 'clair3_concat_gvcfs'

  input:
    tuple val(meta), path(gvcfs), path(gvcfIndexes)
  
  output:
    tuple val(meta), path(gvcfOut), path(gvcfOutIndex), path(gvcfOutStats)
  
  shell:
    gvcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chunk_${meta.chunk.index}_snv.g.vcf.gz"
    gvcfOutIndex = "${gvcfOut}.csi"
    gvcfOutStats = "${gvcfOut}.stats"
    
    // reuse concat_vcf template
    vcfs=gvcfs
    vcfIndexes=gvcfIndexes
    vcfOut = gvcfOut
    vcfOutIndex = gvcfOutIndex
    vcfOutStats = gvcfOutStats
    template 'concat_vcf.sh'
  
  stub:
    gvcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chunk_${meta.chunk.index}_snv.g.vcf.gz"
    gvcfOutIndex = "${gvcfOut}.csi"
    gvcfOutStats = "${gvcfOut}.stats"

    """
    touch "${gvcfOut}"
    touch "${gvcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${gvcfOutStats}"
    """
}

process concat_vcfs {
  label 'clair3_concat_vcfs'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut="${meta.project.id}_snv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'concat.sh'
  
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

process joint_call {
  label 'clair3_joint_call'

  input:
    tuple val(meta), path(gVcfs), path(gVcfIndexes)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut="${meta.project.id}_${meta.chunk.index}_snv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    bed="${meta.project.id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    refSeqFaiPath = params[meta.project.assembly].reference.fastaFai
    config = params.snv.glnexus[meta.project.sequencing_method].preset

    template 'joint_call.sh'

  stub:
    vcfOut="${meta.project.id}_${meta.chunk.index}_snv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}