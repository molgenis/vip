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
    
    decisionTree = params.vcf.classify[params.assembly].decision_tree
    annotateLabels = params.vcf.classify.annotate_labels
    annotatePath = params.vcf.classify.annotate_path
    
    template 'classify.sh'
}
