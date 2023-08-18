process straglr_call {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    reference = params[meta.sample.assembly].reference.fasta
    loci = params.str.straglr[meta.sample.assembly].loci
    minSupport = params.str.straglr.minSupport
    minClusterSize = params.str.straglr.minClusterSize
    sampleId = meta.sample.individual_id
    sampleSex = meta.sample.sex

    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_str.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'stragler_call.sh'

  stub:
    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_str.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}