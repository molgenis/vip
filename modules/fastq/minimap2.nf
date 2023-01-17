process minimap2_align {
  input:
    tuple val(meta), path(fastq)
  output:
    tuple val(meta), path(cram), path(cramCrai)
  shell:
    reference=params[params.assembly].reference.fasta
    referenceMmi="${meta.fasta_mmi}"
    cram="${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"

    preset=params.sequencingMethod == "ONT" ? "map-ont" : ""

    template 'minimap2_align.sh'
}

process minimap2_align_paired_end {
  input:
    tuple val(meta), path(fastqR1), path(fastqR2)
  output:
    tuple val(meta), path(cram), path(cramCrai)
  shell:
    reference=params[params.assembly].reference.fasta
    referenceMmi="${meta.fasta_mmi}"
    cram="${meta.sample.individual_id}.cram"
    cramCrai="${cram}.crai"

    template 'minimap2_align_paired_end.sh'
}

process minimap2_index {
  input:
    val(meta)
  output:
    tuple val(meta), path(fasta_mmi)
  shell:
    reference=params[params.assembly].reference.fasta
    fasta_mmi="reference.mmi"

    template 'minimap2_index.sh'
}
