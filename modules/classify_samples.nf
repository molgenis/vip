process classify_samples {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfSamplesClassifiedPath), path("${vcfSamplesClassifiedPath}.csi")
  shell:
    id = "${vcfPath.simpleName}"
    order = "${meta.chunk.index}"
    vcfSamplesClassifiedPath = "${id}_chunk${order}_samples_classified.vcf.gz"
    template 'classify_samples.sh'
}

process classify_samples_publish {
  publishDir "$params.output/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_samples_classified.vcf.gz"
    template 'merge.sh'
}
