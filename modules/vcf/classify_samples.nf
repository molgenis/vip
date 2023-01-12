include { basename } from './utils'

process classify_samples {
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta)
    vcfOut = "${basename}_classified_samples.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    decisionTree = params.vcf.classify_samples[params.assembly].decision_tree
    annotateLabels = params.vcf.classify_samples.annotate_labels
    annotatePath = params.vcf.classify_samples.annotate_path

    probands = meta.probands.collect{ proband -> proband.individual_id}.join(",")
    
    template 'classify_samples.sh'
}
