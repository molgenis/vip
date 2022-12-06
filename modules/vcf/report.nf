include { createPedigree } from '../utils'

process report {
  publishDir "$params.output", mode: 'copy'

  input:
    tuple val(meta), path(vcf), path(vcf_index)
  output:
    tuple val(meta), path(reportPath)
  shell:
    id = "${vcf.simpleName}"
    vcfOutputPath = "${id}.vcf.gz"
    reportPath = "${id}.html"
    refSeqPath = params[params.assembly].reference.fasta
    genesPath = params[params.assembly + "_report_genes"]
    probands = meta.probands.collect{ proband -> proband.individual_id }.join(",")
    hpoIds = meta.sampleSheet.findAll{ sample -> !sample.hpo_ids.isEmpty() }.collect{ sample -> [sample.individual_id, sample.hpo_ids.join(";")].join("/") }.join(",") 
    pedigree = "pedigree.ped"
    pedigreeContent = createPedigree(meta.sampleSheet)

    template 'report.sh'
}

