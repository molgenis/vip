include { basename } from './utils'

process annotate_publish {
  publishDir "$params.output", mode: 'link'

  input:
    tuple val(meta), path(vcf), path(vcfIndex)
  output:
    tuple val(meta), path(vcf), path(vcfIndex)
  shell:
    '''
    '''
}

process annotate_publish_concat {
  publishDir "$params.output", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)
  shell:
    basename = basename(meta)
    vcfOut="${basename}_annotated.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'concat_publish.sh'
}