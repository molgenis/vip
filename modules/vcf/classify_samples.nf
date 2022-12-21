process classify_samples {
  input:
    tuple val(meta), path(vcf), path(vcfIndex)
  output:
    tuple val(meta), path(vcfOut), path("${vcfOut}.csi")
  shell:
    vcfOut = "${meta.project_id}_chunk_${meta.chunk.index}_classified_samples.vcf.gz"

    decisionTree = params.vcf.classify_samples[params.assembly].decision_tree
    annotateLabels = params.vcf.classify_samples.annotate_labels
    annotatePath = params.vcf.classify_samples.annotate_path

    probands = meta.probands.collect{ proband -> proband.individual_id}.join(",")
    template 'classify_samples.sh'
}
