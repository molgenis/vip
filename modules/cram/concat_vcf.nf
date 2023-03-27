include { basename } from './utils'

process concat_vcf {  
  input:
    tuple val(group), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    key = group[0]
    meta = group[1][0]
    
    basename = basename(key[0],key[1])
    vcfOut = "${basename}_concatted_sorted.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'concat_vcf.sh'
}