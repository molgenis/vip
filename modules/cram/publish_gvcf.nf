process publish_gvcf {
  label 'publish_gvcf'

  publishDir "$params.output/intermediates", mode: 'link'
  
  input:
    tuple val(meta), path(vcfs)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut = "${meta.sample.individual_id}_snv.g.vcf.gz"
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