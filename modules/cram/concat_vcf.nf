include { basename } from './utils'

process concat_vcf {  
  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta.project_id,meta.chunk)
    vcfOut = "${basename}_concatted_sorted.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    template 'concat_vcf.sh'
}