process samtools_index {
  input:
    tuple val(meta), path(cram)
  output:
    tuple val(meta), path(cramIndex)
  shell:
    cramIndex=cram.name.endsWith('.cram') ? "${cram}.crai" : "${cram}.bai"

    template 'samtools_index.sh'
}
