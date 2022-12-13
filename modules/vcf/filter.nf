process filter {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfFilteredPath), path("${vcfFilteredPath}.csi")
  shell:
    vcfFilteredPath = "${meta.project_id}_chunk_${meta.chunk.index}_filtered.vcf.gz"
    vcfSplittedPath = "${meta.project_id}_chunk_${meta.chunk.index}_splitted.vcf.gz"
    template 'filter.sh'
}
