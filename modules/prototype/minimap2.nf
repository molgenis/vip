process minimap2_align {
  input:
    tuple val(meta), path(reference), path(referenceFai), path(referenceGzi), path(referenceMmiIndex)
  output:
    tuple val(meta), path(cram), path(cramCrai)
  script:
    cram="${meta.family_id}_${meta.individual_id}.cram"
    cramCrai="${cram}.crai"
    """
    ${CMD_MINIMAP2} -t ${task.cpus} -a -x sr ${referenceMmiIndex} ${meta.fastq_r1} ${meta.fastq_r2} | \
    ${CMD_SAMTOOLS} fixmate -u -m - - | \
    ${CMD_SAMTOOLS} sort -u -@ ${task.cpus} -T ${TMPDIR} - | \
    ${CMD_SAMTOOLS} markdup -@ ${task.cpus} --reference ${reference} --write-index - ${cram}
    """
}
