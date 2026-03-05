process publish_mtdna_vcf {
  label 'publish_mtdna_vcf'

  publishDir "$params.output/intermediates"

  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    vcfOut = "${meta.project.id}_mtdnasnv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'publish_vcf.sh'

  stub:
    vcfOut = "${meta.project.id}_mtdnasnv.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}