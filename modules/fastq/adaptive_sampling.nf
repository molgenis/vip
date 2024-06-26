process filter_reads {
  label 'filter_reads'

  input:
    tuple val(meta), path(fastqs, arity: '1..*'), path(adaptiveSamplingCsv)

  output:
  	tuple val(meta), path(fastqOut)

  shell:
    fastqOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_filtered.fastq.gz"

    template 'adaptive_sampling_filter_reads.sh'

  stub:
    fastqOut="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_filtered.fastq.gz"

    """
    touch "${fastqOut}"
    """
}
