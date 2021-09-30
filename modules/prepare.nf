process prepare {
  input:
    path(vcfPath)
  output:
    tuple val(id), path(vcfOutputPath), path("${vcfOutputPath}.csi"), path("${vcfOutputPath}.stats")
  shell:
    id="${vcfPath.simpleName}"
    vcfOutputPath="${id}_prepared.vcf.gz"
    template 'prepare.sh'
}
