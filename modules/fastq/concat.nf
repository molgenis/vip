process concat_fastq {
  input:
    tuple val(meta), path(fastq_r1s), path(fastq_r2s)
  output:
    tuple val(meta), path(fastq_r1), path(fastq_r2)
  shell:
    sample_id="${meta.sample.individual_id}"
    fastq_r1="${sample_id}_r1.fastq.gz"
    fastq_r2="${sample_id}_r2.fastq.gz"
    
    template 'concat_fastq.sh'
}
