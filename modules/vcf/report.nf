include { basename } from './utils'
include { createPedigree } from '../utils'

process report {
  label 'vcf_report'
  
  publishDir "$params.output", mode: 'link'

  input:
    tuple val(meta), path(vcf), path(vcfIndex), path(crams)

  output:
    tuple val(meta), path(vcfOut), path(vcfOutIndex), path(reportPath)

  shell:
    basename = basename(meta)
    vcfOut = "${basename}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    vcfOutStats = "${vcfOut}.stats"

    reportPath = "${basename}.html"

    refSeqPath = params[meta.project.assembly].reference.fasta
    decisionTree = params.vcf.classify[meta.project.assembly].decision_tree
    maxRecords = params.vcf.report.max_records
    maxSamples = params.vcf.report.max_samples
    genesPath = params.vcf.report[meta.project.assembly].genes
    template = params.vcf.report.template
    crams = meta.crams ? meta.crams.collect { "${it.individual_id}=${it.cram}" }.join(",") : ""
    includeCrams = params.vcf.report.include_crams

    probands = meta.probands.collect{ proband -> proband.individual_id }.join(",")
    hpoIds = meta.project.samples.findAll{ sample -> !sample.hpo_ids.isEmpty() }.collect{ sample -> [sample.individual_id, sample.hpo_ids.join(";")].join("/") }.join(",") 
    pedigree = "${meta.project.id}.ped"
    pedigreeContent = createPedigree(meta.project.samples)

    template 'report.sh'

  stub:
    basename = basename(meta)
    vcfOut = "${basename}.vcf.gz"
    vcfOutIndex = "${vcfOut}.csi"
    reportPath = "${basename}.html"

    """
    touch "${vcfOut}"
    touch "${vcfOutIndex}"
    touch "${reportPath}"
    """
}

