process annotate {
  input:
    tuple val(meta), path(vcfPath), path(vcfPathCsi)
  output:
    tuple val(meta), path(vcfAnnotatedPath), path("${vcfAnnotatedPath}.csi")
  shell:
    vcfAnnotatedPath = "${meta.project_id}_chunk_${meta.chunk.index}_annotated.vcf.gz"
    vcfCapiceAnnotatedPath = "${meta.project_id}_chunk_${meta.chunk.index}_capice_annotated.vcf.gz"
    capiceInputPath = "${meta.project_id}_chunk_${meta.chunk.index}_capice_input.tsv"
    capiceOutputPath = "${meta.project_id}_chunk_${meta.chunk.index}_capice_output.tsv.gz"
    
    hpoIds = meta.hpo_ids.join(",")
    
    refSeqPath = params[params.assembly].reference.fasta
    vepCustomGnomAdPath = params.vcf.annotate[params.assembly].vep_custom_gnomad
    vepCustomClinVarPath = params.vcf.annotate[params.assembly].vep_custom_clinvar
    vepCustomPhyloPPath = params.vcf.annotate[params.assembly].vep_custom_phylop
    vepPluginArtefact = params.vcf.annotate[params.assembly].vep_plugin_artefact
    vepPluginSpliceAiIndelPath = params.vcf.annotate[params.assembly].vep_plugin_spliceai_indel
    vepPluginSpliceAiSnvPath = params.vcf.annotate[params.assembly].vep_plugin_spliceai_snv
    vepPluginVkglPath = params.vcf.annotate[params.assembly].vep_plugin_vkgl
    vepPluginUtrAnnotatorPath = params.vcf.annotate[params.assembly].vep_plugin_utrannotator
    capiceModelPath = params.vcf.annotate[params.assembly].capice_model
    
    template 'annotate.sh'
}
