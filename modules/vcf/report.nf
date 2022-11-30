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
    probands = meta.probands.collect{ proband -> [proband.family_id, proband.individual_id].join("_")}.join(",")
    hpoIds = meta.hpo_ids.join(",")
    pedigree = "pedigree.ped"
    pedigreeContent = createPedigree(meta.sampleSheet)

    template 'report.sh'
}

