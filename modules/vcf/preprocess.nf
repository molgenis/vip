process preprocess {
  input:
    tuple val(meta), path(vcfPath), path(vcfIndexPath)
  output:
    tuple val(meta), path(vcfPreprocessedPath), path("${vcfPreprocessedPath}.csi")
  shell:
    vcfPreprocessedPath = "${meta.project_id}_chunk_${meta.chunk.index}_preprocessed.vcf.gz"
    refSeqPath = params[params.assembly].reference.fasta
    template 'preprocess.sh'
}
