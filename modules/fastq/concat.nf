process concat_fastq {
  label 'fastq_concat'

  input:
    tuple val(meta), path(fastqs)
  output:
    tuple val(meta), path(fastq)
  shell:
    sample_id="${meta.sample.individual_id}"
    fastq="${sample_id}.fastq.gz"
    
    template 'concat_fastq.sh'
}


process concat_fastq_paired_end {
  label 'fastq_concat_paired_end'
  
  input:
    tuple val(meta), path(fastq_r1s), path(fastq_r2s)
  output:
    tuple val(meta), path(fastq_r1), path(fastq_r2)
  shell:
    sample_id="${meta.sample.individual_id}"
    fastq_r1="${sample_id}_r1.fastq.gz"
    fastq_r2="${sample_id}_r2.fastq.gz"
    
    template 'concat_fastq_paired_end.sh'
}
