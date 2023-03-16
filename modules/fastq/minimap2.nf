process minimap2_align {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(fastq)
  output:
    tuple val(meta), path(cram), path(cramCrai)
  shell:
    reference=params[meta.sample.assembly].reference.fasta
    referenceMmi="${meta.fasta_mmi}"
    cram="${meta.sample.project_id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"

    preset=meta.sample.sequencing_platform == "nanopore" ? "map-ont" : ""

    template 'minimap2_align.sh'
}

process minimap2_align_paired_end {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(fastqR1), path(fastqR2)
  output:
    tuple val(meta), path(cram), path(cramCrai)
  shell:
    reference=params[meta.sample.assembly].reference.fasta
    referenceMmi="${meta.fasta_mmi}"
    cram="${meta.sample.project_id}_${meta.sample.family_id}_${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"

    template 'minimap2_align_paired_end.sh'
}

process minimap2_index {
  input:
    val(meta)
  output:
    tuple val(meta), path(fasta_mmi)
  shell:
    reference=params[meta.sample.assembly].reference.fasta
    fasta_mmi="reference.mmi"

    template 'minimap2_index.sh'
}
