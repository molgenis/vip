process samtools_index {
  input:
    tuple val(meta), path(cram)
  output:
    tuple val(meta), path(cramIndex)
  script:
    cramIndex="${cram}.crai"
    """
    ${CMD_SAMTOOLS} index "${cram}"
    """
}
