process validate {
  label 'cram_validate'

  input:
    tuple val(meta), path(cram)

  output:
    tuple val(meta), path(cramOut), path(cramOutIndex), path(cramOutStats)

  shell:
    reference = params[meta.project.assembly].reference.fasta

    cramOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_validated.bam"
    cramOutIndex = "${cramOut}.bai"
    cramOutStats = "${cramOut}.stats"

    template 'validate.sh'
  
  stub:
    cramOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_validated.bam"
    cramOutIndex = "${cramOut}.bai"
    cramOutStats = "${cramOut}.stats"

    """
    touch "${cramOut}"
    touch "${cramIndex}"
    echo -e "chr1\t248956422\t16617476\t118422" > "${cramStats}"
    """
}