process prepare {
  input:
    tuple val(meta), path(vcfPath), path(vcfIndexPath)
  output:
    tuple val(meta), path(vcfOutputPath), path("${vcfOutputPath}.csi"), path("${vcfOutputPath}.stats")
  shell:
    vcfOutputPath="${meta.project_id}_chunk_${meta.chunk.index}_prepared.vcf.gz"
    template 'prepare.sh'
}
