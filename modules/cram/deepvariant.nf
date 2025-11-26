process call {
  label 'deepvariant_call'

  memory { 2.GB * task.cpus }

  input:
    tuple val(meta), path(cram), path(cramCrai)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    haploidContigs = params[meta.project.assembly].reference.haploidContigs
    parRegionsBed = params[meta.project.assembly].reference.parRegionsBed
    bed="${meta.sample.individual_id}_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")
    sampleName = "${meta.sample.individual_id}"

    vcfOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chunk_${meta.chunk.index}_snv.g.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    model=meta.project.sequencing_platform == "illumina" ? params.snv.deepvariant[meta.project.sequencing_platform][meta.project.sequencing_method].model_name : params.snv.deepvariant[meta.project.sequencing_platform].model_name

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

process call_duo {
  label 'deepvariant_call_duo'

  memory { 4.GB * task.cpus }

  input:
    tuple val(meta), path(cramChild), path(cramCraiChild),
                     path(cramParent), path(cramCraiParent)

  output:
    tuple val(meta), path(gvcfOutChild), path(gvcfOutIndexChild), path(gvcfOutStatsChild),
                     path(gvcfOutParent), path(gvcfOutIndexParent), path(gvcfOutStatsParent)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    haploidContigs = params[meta.project.assembly].reference.haploidContigs
    parRegionsBed = params[meta.project.assembly].reference.parRegionsBed
    bed="regions_chunk_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")

    modelType=meta.project.sequencing_platform == "illumina" ? params.snv.deeptrio[meta.project.sequencing_platform][meta.project.sequencing_method].model_name : params.snv.deeptrio[meta.project.sequencing_platform].model_name

    // include child sample name in parent output filenames to prevent downstream filename collisions
    sampleNameChild=meta.sample.individual_id
    sampleNameParent=meta.sample.paternal_id != null ? meta.sample.paternal_id : meta.sample.maternal_id
    
    gvcfOutPrefix="${meta.project.id}_${meta.sample.family_id}_${sampleNameChild}"
    gvcfOutPostfix="chunk_${meta.chunk.index}_snv"

    gvcfOutChild="${gvcfOutPrefix}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexChild="${gvcfOutChild}.csi"
    gvcfOutStatsChild="${gvcfOutChild}.stats"
    vcfOutChild="${gvcfOutPrefix}_${gvcfOutPostfix}.vcf.gz"

    gvcfOutParent="${gvcfOutPrefix}_${sampleNameParent}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexParent="${gvcfOutParent}.csi"
    gvcfOutStatsParent="${gvcfOutParent}.stats"
    vcfOutParent="${gvcfOutPrefix}_${sampleNameParent}_${gvcfOutPostfix}.vcf.gz"

    template 'deepvariant_call_duo.sh'

  stub:
    // include child sample name in parent output filenames to prevent downstream filename collisions
    sampleNameChild=meta.sample.individual_id
    sampleNameParent=meta.sample.paternal_id != null ? meta.sample.paternal_id : meta.sample.maternal_id
    
    gvcfOutPrefix="${meta.project.id}_${meta.sample.family_id}_${sampleNameChild}"
    gvcfOutPostfix="chunk_${meta.chunk.index}_snv"

    gvcfOutChild="${gvcfOutPrefix}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexChild="${gvcfOutChild}.csi"
    gvcfOutStatsChild="${gvcfOutChild}.stats"
    vcfOutChild="${gvcfOutPrefix}_${gvcfOutPostfix}.vcf.gz"

    gvcfOutParent="${gvcfOutPrefix}_${sampleNameParent}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexParent="${gvcfOutParent}.csi"
    gvcfOutStatsParent="${gvcfOutParent}.stats"
    vcfOutParent="${gvcfOutPrefix}_${sampleNameParent}_${gvcfOutPostfix}.vcf.gz"

    """
    touch "${gvcfOutChild}"
    touch "${gvcfOutIndexChild}"
    echo -e "chr1\t248956422\t1234" > "${gvcfOutStatsChild}"

    touch "${gvcfOutParent}"
    touch "${gvcfOutIndexParent}"
    echo -e "chr1\t248956422\t1234" > "${gvcfOutStatsParent}"
    """
}

process call_trio {
  label 'deepvariant_call_trio'

  memory { 6.GB * task.cpus }

  input:
    tuple val(meta), path(cramChild), path(cramCraiChild),
                     path(cramPaternal), path(cramCraiPaternal),
                     path(cramMaternal), path(cramCraiMaternal)

  output:
    tuple val(meta), path(gvcfOutChild), path(gvcfOutIndexChild), path(gvcfOutStatsChild),
                     path(gvcfOutPaternal), path(gvcfOutIndexPaternal), path(gvcfOutStatsPaternal),
                     path(gvcfOutMaternal), path(gvcfOutIndexMaternal), path(gvcfOutStatsMaternal)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    haploidContigs = params[meta.project.assembly].reference.haploidContigs
    parRegionsBed = params[meta.project.assembly].reference.parRegionsBed
    bed="regions_chunk_${meta.chunk.index}.bed"
    bedContent = meta.chunk.regions.collect { region -> "${region.chrom}\t${region.chromStart}\t${region.chromEnd}" }.join("\n")

    modelType=meta.project.sequencing_platform == "illumina" ? params.snv.deeptrio[meta.project.sequencing_platform][meta.project.sequencing_method].model_name : params.snv.deeptrio[meta.project.sequencing_platform].model_name

    // include child sample name in paternal/maternal output filenames to prevent downstream filename collisions
    sampleNameChild=meta.sample.individual_id
    sampleNamePaternal=meta.sample.paternal_id
    sampleNameMaternal=meta.sample.maternal_id
    
    gvcfOutPrefix="${meta.project.id}_${meta.sample.family_id}_${sampleNameChild}"
    gvcfOutPostfix="chunk_${meta.chunk.index}_snv"

    gvcfOutChild="${gvcfOutPrefix}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexChild="${gvcfOutChild}.csi"
    gvcfOutStatsChild="${gvcfOutChild}.stats"
    vcfOutChild="${gvcfOutPrefix}_${gvcfOutPostfix}.vcf.gz"

    gvcfOutPaternal="${gvcfOutPrefix}_${sampleNamePaternal}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexPaternal="${gvcfOutPaternal}.csi"
    gvcfOutStatsPaternal="${gvcfOutPaternal}.stats"
    vcfOutPaternal="${gvcfOutPrefix}_${sampleNamePaternal}_${gvcfOutPostfix}.vcf.gz"

    gvcfOutMaternal="${gvcfOutPrefix}_${sampleNameMaternal}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexMaternal="${gvcfOutMaternal}.csi"
    gvcfOutStatsMaternal="${gvcfOutMaternal}.stats"
    vcfOutMaternal="${gvcfOutPrefix}_${sampleNameMaternal}_${gvcfOutPostfix}.vcf.gz"

    template 'deepvariant_call_trio.sh'

  stub:
    // include child sample name in paternal/maternal output filenames to prevent downstream filename collisions
    sampleNameChild=meta.sample.individual_id
    sampleNamePaternal=meta.sample.paternal_id
    sampleNameMaternal=meta.sample.maternal_id
    
    gvcfOutPrefix="${meta.project.id}_${meta.sample.family_id}_${sampleNameChild}"
    gvcfOutPostfix="chunk_${meta.chunk.index}_snv"

    gvcfOutChild="${gvcfOutPrefix}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexChild="${gvcfOutChild}.csi"
    gvcfOutStatsChild="${gvcfOutChild}.stats"
    vcfOutChild="${gvcfOutPrefix}_${gvcfOutPostfix}.vcf.gz"

    gvcfOutPaternal="${gvcfOutPrefix}_${sampleNamePaternal}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexPaternal="${gvcfOutPaternal}.csi"
    gvcfOutStatsPaternal="${gvcfOutPaternal}.stats"
    vcfOutPaternal="${gvcfOutPrefix}_${sampleNamePaternal}_${gvcfOutPostfix}.vcf.gz"

    gvcfOutMaternal="${gvcfOutPrefix}_${sampleNameMaternal}_${gvcfOutPostfix}.g.vcf.gz"
    gvcfOutIndexMaternal="${gvcfOutMaternal}.csi"
    gvcfOutStatsMaternal="${gvcfOutMaternal}.stats"
    vcfOutMaternal="${gvcfOutPrefix}_${sampleNameMaternal}_${gvcfOutPostfix}.vcf.gz"

    """
    touch "${gvcfOutChild}"
    touch "${gvcfOutIndexChild}"
    echo -e "chr1\t248956422\t1234" > "${gvcfOutStatsChild}"

    touch "${gvcfOutPaternal}"
    touch "${gvcfOutIndexPaternal}"
    echo -e "chr1\t248956422\t1234" > "${gvcfOutStatsPaternal}"

    touch "${gvcfOutMaternal}"
    touch "${gvcfOutIndexMaternal}"
    echo -e "chr1\t248956422\t1234" > "${gvcfOutStatsMaternal}"
    """
}

process concat_gvcfs {
  label 'deepvariant_concat_gvcfs'

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
  label 'deepvariant_concat_vcfs'

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
  label 'deepvariant_joint_call'

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