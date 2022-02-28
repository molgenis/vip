process filter_inheritance {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfFilteredPath)
  shell:
    vcfFilteredPath = "${id}_chunk${order}_inheritance_filtered.vcf.gz"
    template 'filterInheritance.sh'
}

process filter_inheritance_publish {
  publishDir "$params.output/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_inheritance_filtered.vcf.gz"
    template 'merge.sh'
}
