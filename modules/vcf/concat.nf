include { basename } from './utils'

process concat {
  label 'vcf_concat'
  
  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    basename = basename(meta)
    vcfOut="${basename}_concated.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'concat.sh'
  
  stub:
    basename = basename(meta)
    vcfOut="${basename}_concated.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}