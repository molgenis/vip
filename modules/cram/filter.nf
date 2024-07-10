process filter {
  label 'filter'
  
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(bed), path(cram), path(cramCrai)
  
  output:
    tuple val(meta), path(cramOut), path(cramOutCrai), path(cramOutStats)
  
  shell:
    cramOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_filtered.cram"
    cramOutCrai="${cram}.crai"
    cramOutStats="${cram}.stats"

    template 'filter.sh'
  
  stub:
    cramOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_filtered.cram"
    cramOutCrai="${cram}.crai"
    cramOutStats="${cram}.stats"
    
    """
    touch "${cram}"
    touch "${cramCrai}"
    echo -e "chr1\t248956422\t16617476\t118422" > "${cramStats}"
    """
}