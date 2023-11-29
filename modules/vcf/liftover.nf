process liftover {
  label 'vcf_liftover'
  
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcf)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats), path(vcfOutRejected), path(vcfOutRejectedIndex), path(vcfOutRejectedStats)

  shell:
    chain = params[meta.project.assembly].chain[params.assembly]
    reference = params[params.assembly].reference.fasta

    vcfOut = "${meta.project.id}_liftover_accepted.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    vcfOutRejected = "${meta.project.id}_liftover_rejected.vcf.gz"
    vcfOutRejectedIndex = "${vcfOutRejected}.csi"
    vcfOutRejectedStats = "${vcfOutRejected}.stats"

    template 'liftover.sh'
  
  stub:
    vcfOut = "${meta.project.id}_liftover_accepted.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    vcfOutRejected = "${meta.project.id}_liftover_rejected.vcf.gz"
    vcfOutRejectedIndex = "${vcfOutRejected}.csi"
    vcfOutRejectedStats = "${vcfOutRejected}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"

    touch "${vcfOutRejected}"
    touch "${vcfOutRejectedIndex}"
    """
}