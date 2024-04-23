include { basename } from './utils'

process classify {
  label 'vcf_classify'

  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    basename = basename(meta)
    vcfOut = "${basename}_classified.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    metadata = params.vcf.classify.metadata
    decisionTree = params.vcf.classify[meta.project.assembly].decision_tree
    annotatePath = params.vcf.classify.annotate_path
    
    template 'classify.sh'
  
  stub:
    basename = basename(meta)
    vcfOut = "${basename}_classified.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}

process classify_publish {
  label 'vcf_classify_publish'

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
  
  stub:
    basename = basename(meta)
    vcfOut="${basename}_classifications.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    """
}