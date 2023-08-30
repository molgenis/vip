process merge {
  label 'gvcf_merge'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(gVcfs), path(gVcfIndexes)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut = "${meta.project.id}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    refSeqFaiPath = params[meta.project.assembly].reference.fastaFai
    config = params.gvcf.merge_preset

    template 'merge.sh'
  
  stub:
    vcfOut = "${meta.project.id}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}