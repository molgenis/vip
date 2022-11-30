process samtools_index {
  input:
    tuple val(meta), path(cram)
  output:
    tuple val(meta), path(cramIndex)
  shell:
    cramIndex="${cram}.crai"

    template 'samtools_index.sh'
}
