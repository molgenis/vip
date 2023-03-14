include { basename } from './utils'

process classify {
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta)
    vcfOut = "${basename}_classified.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
    decisionTree = params.vcf.classify[meta.assembly].decision_tree
    annotateLabels = params.vcf.classify.annotate_labels
    annotatePath = params.vcf.classify.annotate_path
    
    template 'classify.sh'
}

process classify_publish {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)
  shell:
    basename = basename(meta)
    vcfOut="${basename}_classifications.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'publish.sh'
}