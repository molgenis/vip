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

    template 'minimap2_align.sh'
}
