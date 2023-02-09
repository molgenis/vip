include { basename } from './utils'
include { createPedigree } from '../utils'

process report {
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

    refSeqPath = params[meta.assembly].reference.fasta
    decisionTree = params.vcf.classify[meta.assembly].decision_tree
    maxRecords = params.vcf.report.max_records
    maxSamples = params.vcf.report.max_samples
    genesPath = params.vcf.report[meta.assembly].genes
    template = params.vcf.report.template
    crams = meta.crams ? meta.crams.collect { "${it.individual_id}=${it.cram}" }.join(",") : "" 

    probands = meta.probands.collect{ proband -> proband.individual_id }.join(",")
    hpoIds = meta.sampleSheet.findAll{ sample -> !sample.hpo_ids.isEmpty() }.collect{ sample -> [sample.individual_id, sample.hpo_ids.join(";")].join("/") }.join(",") 
    pedigree = "${meta.project_id}.ped"
    pedigreeContent = createPedigree(meta.sampleSheet)

    template 'report.sh'
}

