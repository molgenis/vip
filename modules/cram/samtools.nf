process samtools_index {
  input:
    tuple val(meta), path(cram)
  output:
    tuple val(meta), path(cramIndex)
  shell:
    cramIndex=cram.name.endsWith('.cram') ? "${cram}.crai" : "${cram}.bai"

    template 'samtools_index.sh'
}

process samtools_addreplacerg
 {
  input:
    tuple val(meta), path(cram)
  output:
    tuple val(meta), path(cramOut), path(cramIndex)
  shell:
    cramOut="rg_added_${cram}"
    cramIndex=cram.name.endsWith('.cram') ? "rg_added_${cram}.crai" : "rg_added_${cram}.bai"

    template 'samtools_addreplacerg.sh'
}
