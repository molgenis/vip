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
    vepCustomGnomAdPath = params.vcf.annotate[params.assembly].vep_custom_gnomad
    vepCustomClinVarPath = params.vcf.annotate[params.assembly].vep_custom_clinvar
    vepCustomPhyloPPath = params.vcf.annotate[params.assembly].vep_custom_phylop
    vepPluginArtefact = params.vcf.annotate[params.assembly].vep_plugin_artefact
    vepPluginSpliceAiIndelPath = params.vcf.annotate[params.assembly].vep_plugin_spliceai_indel
    vepPluginSpliceAiSnvPath = params.vcf.annotate[params.assembly].vep_plugin_spliceai_snv
    vepPluginVkglPath = params.vcf.annotate[params.assembly].vep_plugin_vkgl
    vepPluginUtrAnnotatorPath = params.vcf.annotate[params.assembly].vep_plugin_utrannotator
    vcfCapiceAnnotatedPath = "${id}_chunk${order}_capice_annotated.vcf.gz"
    capiceInputPath = "${id}_chunk${order}_capice_input.tsv"
    capiceOutputPath = "${id}_chunk${order}_capice_output.tsv.gz"
    capiceModelPath = params.vcf.annotate[params.assembly].capice_model
    hpoIds = meta.hpo_ids.join(",")
    
    template 'annotate.sh'
}
