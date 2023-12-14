process liftover {
  label 'gvcf_liftover'
  
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(gVcf)

  output:
    tuple val(meta), path(gVcfOut), path(gVcfOutIndex), path(gVcfOutStats), path(gVcfOutRejected), path(gVcfOutRejectedIndex), path(gVcfOutRejectedStats)

  shell:
    chain = params[meta.sample.assembly].chain[params.assembly]
    reference = params[params.assembly].reference.fasta

    gVcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_liftover_accepted.g.vcf.gz"
    gVcfOutIndex = "${gVcfOut}.csi"
    gVcfOutStats = "${gVcfOut}.stats"

    gVcfOutRejected = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_liftover_rejected.g.vcf.gz"
    gVcfOutRejectedIndex = "${gVcfOutRejected}.csi"
    gVcfOutRejectedStats = "${gVcfOutRejected}.stats"

    template 'liftover.sh'
  
  stub:
    gVcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_liftover_accepted.g.vcf.gz"
    gVcfOutIndex = "${gVcfOut}.csi"
    gVcfOutStats = "${gVcfOut}.stats"

    gVcfOutRejected = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_liftover_rejected.g.vcf.gz"
    gVcfOutRejectedIndex = "${gVcfOutRejected}.csi"
    gVcfOutRejectedStats = "${gVcfOutRejected}.stats"

    """
    touch "${gVcfOut}"
    touch "${gVcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${gVcfOutStats}"

    touch "${gVcfOutRejected}"
    touch "${gVcfOutRejectedIndex}"
    """
}