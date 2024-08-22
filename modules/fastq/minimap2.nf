process minimap2_align {
  label 'minimap2_align'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(fastq, arity: '1')

  output:
    tuple val(meta), path(cram), path(cramCrai), path(cramStats)

  shell:
    reference=params[params.assembly].reference.fasta
    referenceMmi=params[params.assembly].reference.fastaMmi
    cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"
    cramStats="${cram}.stats"
    
    sampleId=meta.sample.individual_id;
    platform=meta.project.sequencing_platform
    preset=platform == "nanopore" ? params.minimap2.nanopore_preset : (platform == "pacbio_hifi" ? "map-hifi" : "")
    softClipping=params.minimap2.soft_clipping
		markDuplicates=platform != "nanopore"

    template 'minimap2_align.sh'

  stub:
    cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"
    cramStats="${cram}.stats"
    
    """
    touch "${cram}"
    touch "${cramCrai}"
    echo -e "chr1\t248956422\t16617476\t118422" > "${cramStats}"
    """
}

process minimap2_align_paired_end {
  label 'minimap2_align_paired_end'

  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(fastqR1, arity: '1'), path(fastqR2, arity: '1')

  output:
    tuple val(meta), path(cram), path(cramCrai), path(cramStats)

  shell:
    reference=params[params.assembly].reference.fasta
    referenceMmi=params[params.assembly].reference.fastaMmi
    cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"
    cramStats="${cram}.stats"

    sampleId=meta.sample.individual_id
    platform=meta.project.sequencing_platform
    softClipping=params.minimap2.soft_clipping
		markDuplicates=platform != "nanopore"

    template 'minimap2_align_paired_end.sh'
  
  stub:
    cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"
    cramStats="${cram}.stats"
    
    """
    touch "${cram}"    
    touch "${cramCrai}"
    echo -e "chr1\t248956422\t16617476\t118422" > "${cramStats}"
    """
}
