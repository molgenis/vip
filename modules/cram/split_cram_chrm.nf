process split_cram_chrm {
  label 'split_cram_chrm'

  input:
    tuple val(meta), path(cram), path(cramCrai)

  output:
    tuple val(meta), path(chrmCramOut), path(chrmCramOutIndex), path(chrmCramOutStats), path(nonchrmCramOut), path(nonchrmCramOutIndex), path(nonchrmCramOutStats)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    chrmName = params.cram.mitochondria[meta.project.assembly].chrm_name

    chrmCramOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_chrm.cram"
    chrmCramOutIndex = "${chrmCramOut}.crai"
    chrmCramOutStats = "${chrmCramOut}.stats"
    nonchrmCramOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_nonchrm.cram"
    nonchrmCramOutIndex = "${nonchrmCramOut}.crai"
    nonchrmCramOutStats = "${nonchrmCramOut}.stats"

    template 'split_cram_chrm.sh'
}