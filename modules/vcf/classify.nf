process classify {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfClassifiedPath), path("${vcfClassifiedPath}.csi")
  shell:
    vcfClassifiedPath = "${meta.project_id}_chunk_${meta.chunk.index}_classified.vcf.gz"
    
    decisionTree = params.vcf.classify[params.assembly].decision_tree
    annotateLabels = params.vcf.classify.annotate_labels
    annotatePath = params.vcf.classify.annotate_path
    
    template 'classify.sh'
}
