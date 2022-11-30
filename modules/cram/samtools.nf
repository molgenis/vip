process samtools_index {
  input:
    tuple val(meta), path(cram)
  output:
    tuple val(meta), path(cramIndex)
  script:
    cramIndex="${cram}.crai"

    template 'samtools_index.sh'
}
