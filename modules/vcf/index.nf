process index {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfIndex)
  shell:
    vcfIndex = "${vcf}.csi"

    template 'index.sh'
}