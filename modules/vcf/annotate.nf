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

process annotate_rna {

  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(vcfStats)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    basename = basename(meta)
    vcfOut = "${basename}_annotated.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"
    rna_res = meta.project.samples.rna_res[0]
    sampleid = meta.project.samples.individual_id[0]
    res_to_bed = "/groups/umcg-gdio/tmp01/umcg-tniemeijer/rna_vip/vip/utils/convert_res_to_bed.py"

    fraser_header = params.vcf.annotate.headers.fraser
    outrider_header = params.vcf.annotate.headers.outrider
    mae_header = params.vcf.annotate.headers.mae

    template 'annotate_rna.sh'

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
