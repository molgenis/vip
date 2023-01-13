include { isGVcf } from './utils'

process convert {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = "${vcf.simpleName}_converted"
    vcfOut = isGVcf(vcf) ? "${basename}.g.vcf.gz" : "${basename}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'convert.sh'
}
