include { basename } from './utils'

process concat {
  publishDir "$params.output", mode: 'link'
  
  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path("${vcfOutIndex}")
  shell:
    basename = basename(meta)
    vcfOut="${basename}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    
    template 'concat.sh'
}