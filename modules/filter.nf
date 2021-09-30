process filter {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfFilteredPath)
  shell:
    vcfFilteredPath = "${id}_chunk${order}_filtered.vcf.gz"
    template 'filter.sh'
}

process filter_publish {
  publishDir "$params.outputDir/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_filtered.vcf.gz"
    template 'merge.sh'
}
