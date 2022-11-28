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

process filter_samples_publish {
  publishDir "$params.output/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_samples_filtered.vcf.gz"
    template 'merge.sh'
}
