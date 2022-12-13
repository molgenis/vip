process filter_samples {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfFilteredSamplesPath), path("${vcfFilteredSamplesPath}.csi")
  shell:
    vcfFilteredSamplesPath = "${meta.project_id}_chunk_${meta.chunk.index}_filtered_samples.vcf.gz"
    vcfSplittedSamplesPath = "${meta.project_id}_chunk_${meta.chunk.index}_splitted_samples.vcf.gz"
    template 'filter_samples.sh'
}
