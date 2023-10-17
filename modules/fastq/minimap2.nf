process minimap2_align {
  label 'minimap2_align'

  input:
    tuple val(meta), path(fastq), val(fastq_size), val(fastq_nr)

  output:
    tuple val(meta), path(cram), path(cramCrai), path(cramStats), val(fastq_size)

  shell:
    reference=params[meta.project.assembly].reference.fasta
    referenceMmi=params[meta.project.assembly].reference.fastaMmi
    //fastq_nr prevent naming collisions when merging crams
    cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_${fastq_nr}.cram"
    cramCrai="${cram}.crai"
    cramStats="${cram}.stats"
    
    sampleId=meta.sample.individual_id;
    platform=meta.project.sequencing_platform
    preset=platform == "nanopore" ? "map-ont" : (platform == "pacbio_hifi" ? "map-hifi" : "")
    softClipping=params.minimap2.soft_clipping 

    template 'minimap2_align.sh'
  
  stub:
    cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_${fastq_nr}.cram"
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

  input:
    tuple val(meta), path(fastqR1), path(fastqR2), val(fastq_size), val(fastq_nr)

  output:
    tuple val(meta), path(cram), path(cramCrai), path(cramStats), val(fastq_size)

  shell:
    reference=params[meta.project.assembly].reference.fasta
    referenceMmi=params[meta.project.assembly].reference.fastaMmi
    //fastq_nr prevent naming collisions when merging crams
    cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_${fastq_nr}.cram"
    cramCrai="${cram}.crai"
    cramStats="${cram}.stats"

    sampleId=meta.sample.individual_id
    platform=meta.project.sequencing_platform
    softClipping=params.minimap2.soft_clipping 

    template 'minimap2_align_paired_end.sh'
  
  stub:
    cram="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_${fastq_nr}.cram"
    cramCrai="${cram}.crai"
    cramStats="${cram}.stats"
    
    """
    touch "${cram}"
    touch "${cramCrai}"
    echo -e "chr1\t248956422\t16617476\t118422" > "${cramStats}"
    """
}
