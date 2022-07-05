process filter_samples {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfFilteredSamplesPath)
  shell:
    vcfFilteredSamplesPath = "${id}_chunk${order}_samples_filtered.vcf.gz"
    vcfSplittedSamplesPath = "${id}_chunk${order}_samples_splitted.vcf.gz"
    template 'filter_samples.sh'
}

process filter_samples_publish {
  publishDir "$params.output/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_samples_filtered.vcf.gz"
    template 'merge.sh'
}
