include { basename } from './utils'

process classify_samples {
  label 'vcf_classify_samples'

  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    basename = basename(meta)
    vcfOut = "${basename}_classified_samples.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

		metadata = params.vcf.classify_samples.metadata
    decisionTree = params.vcf.classify_samples[meta.project.assembly].decision_tree
    annotateLabels = params.vcf.classify_samples.annotate_labels
    annotatePath = params.vcf.classify_samples.annotate_path

    probands = meta.probands.collect{ proband -> proband.individual_id}.join(",")
    
    template 'classify_samples.sh'
  
  stub:
    basename = basename(meta)
    vcfOut = "${basename}_classified_samples.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}

process classify_samples_publish {
  label 'vcf_classify_samples_publish'

  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)
    
  shell:
    basename = basename(meta)
    vcfOut="${basename}_sample_classifications.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'publish.sh'
  
  stub:
    basename = basename(meta)
    vcfOut="${basename}_sample_classifications.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    """
}