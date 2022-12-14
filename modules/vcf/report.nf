include { createPedigree } from '../utils'

process report {
  publishDir "$params.output", mode: 'link'

  input:
    tuple val(meta), path(vcf), path(vcf_index)
  output:
    tuple val(meta), path(reportPath)
  shell:
    vcfOutputPath = "${meta.project_id}.vcf.gz"
    reportPath = "${meta.project_id}.html"
    refSeqPath = params[params.assembly].reference.fasta
    genesPath = params.vcf.report[params.assembly].genes
    probands = meta.probands.collect{ proband -> proband.individual_id }.join(",")
    hpoIds = meta.sampleSheet.findAll{ sample -> !sample.hpo_ids.isEmpty() }.collect{ sample -> [sample.individual_id, sample.hpo_ids.join(";")].join("/") }.join(",") 
    pedigree = "${meta.project_id}.ped"
    pedigreeContent = createPedigree(meta.sampleSheet)

    template 'report.sh'
}

