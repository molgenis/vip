process index {
  input:
    tuple val(meta), path(vcf)
  output:
    tuple val(meta), path(vcfOutIndex), path(vcfOutStats)
  shell:
    vcfOutIndex = "${vcf}.csi"
    vcfOutStats = "${vcf}.stats"

    template 'index.sh'
}