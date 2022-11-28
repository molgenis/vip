process filter {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfFilteredPath), path("${vcfFilteredPath}.csi")
  shell:
    id = "${vcfPath.simpleName}"
    order = "${meta.chunk.index}"
    vcfFilteredPath = "${id}_chunk${order}_filtered.vcf.gz"
    vcfSplittedPath = "${id}_chunk${order}_splitted.vcf.gz"
    template 'filter.sh'
}

process filter_publish {
  publishDir "$params.output/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_filtered.vcf.gz"
    template 'merge.sh'
}
