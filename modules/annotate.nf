process annotate {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfAnnotatedPath)
  shell:
    vcfAnnotatedPath = "${id}_chunk${order}_annotated.vcf.gz"
    refSeqPath = params[params.assembly + "_reference"]
    vepCustomGnomAdPath = params[params.assembly + "_annotate_vep_custom_gnomad"]
    vepPluginArtefact = params[params.assembly + "_annotate_vep_plugin_artefact"]
    vepPluginSpliceAiIndelPath = params[params.assembly + "_annotate_vep_plugin_spliceai_indel"]
    vepPluginSpliceAiSnvPath = params[params.assembly + "_annotate_vep_plugin_spliceai_snv"]
    vepPluginVkglPath = params[params.assembly + "_annotate_vep_plugin_vkgl"]

    template 'annotate.sh'
}

process annotate_publish {
  publishDir "$params.output/intermediates", mode: 'copy'

  when: "$params.keep" == true

  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath), path("${vcfMergedPath}.csi")
  shell:
    vcfMergedPath = "${id}_annotated.vcf.gz"
    template 'merge.sh'
}
