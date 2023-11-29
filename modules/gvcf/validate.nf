process validate {
  label 'gvcf_validate'

  input:
    tuple val(meta), path(gVcf)

  output:
    tuple val(meta), path(gVcfOut), path(gVcfOutIndex), path(gVcfOutStats)

  shell:
    sampleId = "${meta.sample.individual_id}"
    assembly = meta.sample.assembly
    reference = params[meta.sample.assembly].reference.fasta
    referenceFai = params[meta.sample.assembly].reference.fastaFai

    gVcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_validated.g.vcf.gz"
    gVcfOutIndex = "${gVcfOut}.csi"
    gVcfOutStats = "${gVcfOut}.stats"

    template 'validate.sh'
  
  stub:
    gVcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_validated.g.vcf.gz"
    gVcfOutIndex = "${gVcfOut}.csi"
    gVcfOutStats = "${gVcfOut}.stats"

    """
    touch "${gVcfOut}"
    touch "${gVcfOutIndex}"
    echo -e "chr1\t248956422\t16617476\t118422" > "${gVcfOutStats}"
    """
}
