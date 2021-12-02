process preprocess {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfPreprocessedPath)
  shell:
    vcfPreprocessedPath = "${id}_chunk${order}_preprocessed.vcf.gz"
    refSeqPath = params[params.assembly + "_reference"]
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
