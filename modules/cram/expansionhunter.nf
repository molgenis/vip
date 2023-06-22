process expansionhunter_call {
  publishDir "$params.output/intermediates", mode: 'link'

  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex)
  shell:
    paramReference = params[meta.sample.assembly].reference.fasta
    paramReferenceFai = params[meta.sample.assembly].reference.fastaFai

    paramAligner = params.cram.expansionhunter.aligner
    paramAnalysisMode = params.cram.expansionhunter.analysis_mode
    paramLogLevel = params.cram.expansionhunter.log_level
    paramRegionExtensionLength = params.cram.expansionhunter.region_extension_length
    paramVariantCatalog = params.cram.expansionhunter[meta.sample.assembly].variant_catalog

    sampleId = meta.sample.individual_id
    sampleSex = meta.sample.sex != null ? meta.sample.sex : "female" // ExpansionHunter assumes 'female' by default

    vcfOut = "${meta.sample.project_id}_${meta.sample.family_id}_${meta.sample.individual_id}_str.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    template 'expansionhunter_call.sh'
}