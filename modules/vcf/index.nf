process index {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path("${vcf}.csi")
  shell:
    template 'index.sh'
}