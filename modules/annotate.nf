process annotate {
  input:
    tuple val(id), val(order), path(vcfPath)
  output:
    tuple val(id), val(order), path(vcfAnnotatedPath)
  shell:
    vcfAnnotatedPath = "${id}_chunk${order}_annotated.vcf.gz"
    refSeqPath = params[params.assembly + "_reference"]
    vepCustomGnomAdPath = params[params.assembly + "_annotate_vep_custom_gnomad"]
    vepCustomClinVarPath = params[params.assembly + "_annotate_vep_custom_clinvar"]
    vepCustomPhyloPPath = params[params.assembly + "_annotate_vep_custom_phylop"]
    vepPluginArtefact = params[params.assembly + "_annotate_vep_plugin_artefact"]
    vepPluginSpliceAiIndelPath = params[params.assembly + "_annotate_vep_plugin_spliceai_indel"]
    vepPluginSpliceAiSnvPath = params[params.assembly + "_annotate_vep_plugin_spliceai_snv"]
    vepPluginVkglPath = params[params.assembly + "_annotate_vep_plugin_vkgl"]
    vepPluginUtrAnnotatorPath = params[params.assembly + "_annotate_vep_plugin_utrannotator"]
    vcfCapiceAnnotatedPath = "${id}_chunk${order}_capice_annotated.vcf.gz"
    capiceInputPath = "${id}_chunk${order}_capice_input.tsv"
    capiceOutputPath = "${id}_chunk${order}_capice_output.tsv.gz"
    capiceModelPath = params[params.assembly + "_annotate_capice_model"]
    greenDbConstraintPath = params[params.assembly + "_constraint_GREEN_DB"]
    dnaseRegionsPath = params[params.assembly + "_DNase_regions"]
    tfbsRegionsPath = params[params.assembly + "_TFBS_regions"]
    ucneRegionsPath = params[params.assembly + "_UCNE_regions"]

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
