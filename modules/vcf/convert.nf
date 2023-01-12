include { basename } from './utils'

process convert {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)
  shell:
    vcfOut = "${vcf.simpleName}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'convert.sh'
}
