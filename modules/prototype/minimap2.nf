process minimap2_align {
  input:
    tuple val(meta), path(fastqR1), path(fastqR2), path(reference), path(referenceFai), path(referenceGzi), path(referenceMmi)
  output:
    tuple val(meta), path(cram), path(cramCrai)
  script:
    cram="${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"
    """
    ${CMD_MINIMAP2} -t ${task.cpus} -a -x sr ${referenceMmi} ${fastqR1} ${fastqR2} | \
    ${CMD_SAMTOOLS} fixmate -u -m - - | \
    ${CMD_SAMTOOLS} sort -u -@ ${task.cpus} - | \
    ${CMD_SAMTOOLS} markdup -@ ${task.cpus} --reference ${reference} --write-index - ${cram}
    """
}
