process classify {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfClassifiedPath)
  shell:
    vcfClassifiedPath = "${id}_chunk${order}_classified.vcf.gz"
    template 'classify.sh'
}

process classify_publish {
  publishDir "$params.outputDir/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_classified.vcf.gz"
    template 'merge.sh'
}
