process call_publish {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)
  output:
    tuple path(vcfOut), path(vcfOutIndex)
  shell:
    vcfOut="${meta.project_id}_merged.vcf.gz"
    vcfOutIndex="${vcfOut}.csi"

    template 'publish.sh'
}