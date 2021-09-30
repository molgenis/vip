process report {
  publishDir "$params.outputDir", mode: 'copy'

  input:
    tuple val(id), path(vcfPath)
  output:
    tuple val(id), path(vcfOutputPath), path("${vcfOutputPath}.csi"), path("${vcfOutputPath}.md5"), path(reportPath), path("${reportPath}.md5")
  shell:
    vcfOutputPath = "${id}.vcf.gz"
    reportPath = "${id}.html"
    template 'report.sh'
}

