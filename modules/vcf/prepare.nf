process prepare {
  input:
    tuple val(meta), path(vcfPath), path(vcfIndexPath)
  output:
    tuple val(meta), path(vcfOutputPath), path("${vcfOutputPath}.csi")
  shell:
    id="${vcfPath.simpleName}"
    vcfOutputPath="${id}_prepared.vcf.gz"
    template 'prepare.sh'
}
