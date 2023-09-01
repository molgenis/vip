include { basename; getProbandHpoIds; areProbandHpoIdsIndentical } from './utils'

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
    vepCustomGnomAdPath = params.vcf.annotate[assembly].vep_custom_gnomad
    vepCustomClinVarPath = params.vcf.annotate[assembly].vep_custom_clinvar
    vepCustomPhyloPPath = params.vcf.annotate[assembly].vep_custom_phylop
    vepPluginSpliceAiIndelPath = params.vcf.annotate[assembly].vep_plugin_spliceai_indel
    vepPluginSpliceAiSnvPath = params.vcf.annotate[assembly].vep_plugin_spliceai_snv
    vepPluginVkglPath = params.vcf.annotate[assembly].vep_plugin_vkgl
    vepPluginUtrAnnotatorPath = params.vcf.annotate[assembly].vep_plugin_utrannotator
    capiceModelPath = params.vcf.annotate[assembly].capice_model
    alphScorePath = params.vcf.annotate[assembly].vep_plugin_alphscore
    geneNameEntrezIdMappingPath = params.vcf.annotate.gene_name_entrez_id_mapping

    gadoGenesPath = params.vcf.annotate.gado_genes
    gadoHpoPath = params.vcf.annotate.gado_hpo
    gadoPredictInfoPath = params.vcf.annotate.gado_predict_info
    gadoPredictMatrixPath = params.vcf.annotate.gado_predict_matrix
    areProbandHpoIdsIndentical = areProbandHpoIdsIndentical(meta.project.samples)
    gadoHpoIds = getProbandHpoIds(meta.project.samples).join(",")

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
  label 'annotate_publish'
  
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
