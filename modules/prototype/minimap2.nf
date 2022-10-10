process minimap2_align {
  input:
    tuple val(meta), path(fastqR1), path(fastqR2)
  output:
    tuple val(meta), path(cram), path(cramCrai)
  script:
    reference=params[params.assembly].reference.fasta
    referenceMmi=params[params.assembly].reference.fastaMmi
    cram="${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"
    """
    ${CMD_MINIMAP2} -t ${task.cpus} -a -x sr ${referenceMmi} ${fastqR1} ${fastqR2} | \
    ${CMD_SAMTOOLS} fixmate -u -m - - | \
    ${CMD_SAMTOOLS} sort -u -@ ${task.cpus} - | \
    ${CMD_SAMTOOLS} markdup -@ ${task.cpus} --reference ${reference} --write-index - ${cram}
    """
}
