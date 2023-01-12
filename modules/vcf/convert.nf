process convert {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    vcfOut = "${vcf.simpleName}_converted.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'convert.sh'
}
