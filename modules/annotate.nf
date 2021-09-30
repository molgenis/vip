process annotate {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfAnnotatedPath)
  shell:
    vcfAnnotatedPath = "${id}_chunk${order}_annotated.vcf.gz"
    template 'annotate.sh'
}

process annotate_publish {
  publishDir "$params.outputDir/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_annotated.vcf.gz"
    template 'merge.sh'
}
