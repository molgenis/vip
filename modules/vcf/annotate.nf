include { basename; areProbandHpoIdsIndentical } from './utils'

process annotate {
  label 'vcf_annotate'

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
    
    assembly=meta.project.assembly
    refSeqPath = params[assembly].reference.fasta
    vepCustomPhyloPPath = params.vcf.annotate[assembly].vep_custom_phylop
    vepPluginClinVarPath = params.vcf.annotate[assembly].vep_plugin_clinvar
    vepPluginGnomAdPath = params.vcf.annotate[assembly].vep_plugin_gnomad
    vepPluginSpliceAiIndelPath = params.vcf.annotate[assembly].vep_plugin_spliceai_indel
    vepPluginSpliceAiSnvPath = params.vcf.annotate[assembly].vep_plugin_spliceai_snv
    vepPluginVkglPath = params.vcf.annotate[assembly].vep_plugin_vkgl
    vepPluginUtrAnnotatorPath = params.vcf.annotate[assembly].vep_plugin_utrannotator
    vepPluginNcerPath = params.vcf.annotate[assembly].vep_plugin_ncer
    vepPluginGreenDbPath = params.vcf.annotate[assembly].vep_plugin_green_db
    vepPluginGreenDbEnabled = params.vcf.annotate.vep_plugin_green_db_enabled
    vepPluginREVEL = params.vcf.annotate[assembly].vep_plugin_revel
    fathmmMKLScoresPath = params.vcf.annotate[assembly].vep_plugin_fathmm_MKL_scores
    reMMScoresPath = params.vcf.annotate[assembly].vep_plugin_ReMM_scores
    capiceModelPath = params.vcf.annotate[assembly].capice_model
    alphScorePath = params.vcf.annotate[assembly].vep_plugin_alphscore
    strangerCatalog = params.vcf.annotate[assembly].stranger_catalog

    areProbandHpoIdsIndentical = areProbandHpoIdsIndentical(meta.project.samples)
    gadoScores = meta.gado != null ? meta.gado : ""

    template 'annotate.sh'

  stub:
    basename = basename(meta)
    vcfOut = "${basename}_annotated.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """
}

process annotate_publish {
  label 'vcf_annotate_publish'
  
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(vcfs), path(vcfIndexes)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)

  shell:
    basename = basename(meta)
    vcfOut="${basename}_annotations.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    template 'publish.sh'

  stub:
    basename = basename(meta)
    vcfOut="${basename}_annotations.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    """
}
