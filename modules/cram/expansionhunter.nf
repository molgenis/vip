process expansionhunter_call {
  label 'expansionhunter_call'
  
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(vcfOutStats)

  shell:
    paramReference = params[meta.project.assembly].reference.fasta
    paramReferenceFai = params[meta.project.assembly].reference.fastaFai

    paramAligner = params.str.expansionhunter.aligner
    paramAnalysisMode = params.str.expansionhunter.analysis_mode
    paramLogLevel = params.str.expansionhunter.log_level
    paramRegionExtensionLength = params.str.expansionhunter.region_extension_length
    paramVariantCatalog = params.str.expansionhunter[meta.project.assembly].variant_catalog

    sampleId = meta.sample.individual_id
    sampleSex = meta.sample.sex != "unknown" ? meta.sample.sex : "female" // ExpansionHunter assumes 'female' by default

    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_str.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'expansionhunter_call.sh'
  
  stub:
    vcfOut = "${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}_str.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    echo -e "chr1\t248956422\t1234" > "${vcfOutStats}"
    """

}