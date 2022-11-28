process preprocess {
  input:
    tuple val(meta), path(vcfPath), path(vcfIndexPath)
  output:
    tuple val(meta), path(vcfPreprocessedPath), path("${vcfPreprocessedPath}.csi")
  shell:
    vcfPreprocessedPath = "${vcfPath.simpleName}.preprocessed.vcf.gz"
    refSeqPath = params[params.assembly].reference.fasta
    template 'preprocess.sh'
}

process preprocess_publish {
  publishDir "$params.output/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_preprocessed.vcf.gz"
    template 'merge.sh'
}
