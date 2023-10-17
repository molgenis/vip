process manta_joint_call {
  label 'manta_joint_call'
  
  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(crams), path(cramCrais)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    refSeqPath = params[meta.project.assembly].reference.fasta
    reference = refSeqPath.substring(0, refSeqPath.lastIndexOf('.'))
    sequencingMethod = meta.project.sequencing_method

    vcfOut="${meta.project.id}_sv.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    template 'manta_joint_call.sh'
  
  stub:
    vcfOut="${meta.project.id}_sv.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"
    vcfOutStats="${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}