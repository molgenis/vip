process publish_vcf {
  label 'publish_vcf'

  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(vcfs), path(vcfIndices), path(vcfStats)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut = "${meta.project.id}_snv.g.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'concat_vcf.sh'

  stub:
    vcfOut = "${meta.project.id}_snv.g.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}