process report {
  publishDir "$params.output", mode: 'copy'

  input:
    tuple val(id), path(vcfPath)
  output:
    tuple val(id), path(vcfOutputPath), path("${vcfOutputPath}.csi"), path("${vcfOutputPath}.md5"), path(reportPath), path("${reportPath}.md5")
  shell:
    vcfOutputPath = "${id}.vcf.gz"
    reportPath = "${id}.html"
    refSeqPath = params[params.assembly + "_reference"]
    genesPath = params[params.assembly + "_report_genes"]

    template 'report.sh'
}

