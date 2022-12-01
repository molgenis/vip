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
