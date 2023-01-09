include { basename } from './utils'

process annotate {
  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)
  shell:
    basename = basename(meta)
    vcfOut = "${basename}_annotated.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    
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
