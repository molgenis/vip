process merge_cram{
  label 'merge_cram'

  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(crams)
  output:
    tuple val(meta), path(cramOut), path(cramOutCrai), path(cramOutStats)
  shell:
    reference=params[meta.project.assembly].reference.fasta
    isPairEnded = meta.sample.fastq.isEmpty()
    
    platform=meta.project.sequencing_platform
    cramOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramOutCrai="${cramOut}.crai"
    cramOutStats="${cramOut}.stats"
    
    template 'merge_cram.sh'

  stub:
    cramOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramOutCrai="${cramOut}.crai"
    cramOutStats="${cramOut}.stats"
    """
    touch "${cramOut}"
    touch "${cramOutCrai}"
    echo -e "chr1\t248956422\t16617476\t118422" > "${cramOutStats}"
    """
}