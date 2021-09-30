process inheritance {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfInheritancePath)
  shell:
    vcfInheritancePath = "${id}_chunk${order}_inheritance.vcf.gz"
    template 'inheritance.sh'
}

process inheritance_publish {
  publishDir "$params.output", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_inheritance.vcf.gz"
    template 'merge.sh'
}
