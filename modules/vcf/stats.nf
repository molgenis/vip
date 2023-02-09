process stats {
  input:
    tuple val(meta), path(vcf), path(vcfIndex)
  output:
    tuple val(meta), path(vcfOutStats)
  shell:
    vcfOutStats = "${vcf}.stats"

    template 'stats.sh'
}