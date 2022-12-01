process filter_samples {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfFilteredSamplesPath), path("${vcfFilteredSamplesPath}.csi")
  shell:
    id = "${vcfPath.simpleName}"
    order = "${meta.chunk.index}"
    vcfFilteredSamplesPath = "${id}_chunk${order}_samples_filtered.vcf.gz"
    vcfSplittedSamplesPath = "${id}_chunk${order}_samples_splitted.vcf.gz"
    template 'filter_samples.sh'
}
