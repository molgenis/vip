process annotate {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfAnnotatedPath), path("${vcfAnnotatedPath}.csi")
  shell:
    id = "${vcfPath.simpleName}"
    order = "${meta.chunk.index}"
    vcfAnnotatedPath = "${id}_chunk${order}_annotated.vcf.gz"
    refSeqPath = params[params.assembly].reference.fasta
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
    hpoIds = meta.hpo_ids.join(",")
    
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
