process convert {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfOut), path("${vcfOut}.csi")
  shell:
    vcfOut="${vcf.simpleName}.vcf.gz"
    template 'convert.sh'
}
