process fastp {
  label 'fastp'

  publishDir "$params.output/intermediates/fastp", mode: 'link'

  input:
    tuple val(meta), path(fastqs, arity: '1..*')

  output:
    tuple val(meta), path(fastqPass)                    , emit: reads_pass, optional: true
    tuple val(meta), path(fastqFail)                    , emit: reads_fail, optional: true
    tuple val(meta), path(reportHtml), path(reportJson) , emit: report

  shell:
    basename="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}"

    fastqPass="${basename}_pass.fastq.gz"
    fastqFail="${basename}_fail.fastq.gz"
    reportHtml="${basename}_report.html"
    reportJson="${basename}_report.json"
    options=params.fastp.options

    template 'fastp.sh'

  stub:
    basename="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}"

    fastqPass="${basename}_pass.fastq.gz"
    fastqFail="${basename}_fail.fastq.gz"
    reportHtml="${basename}_report.html"
    reportJson="${basename}_report.json"

    """
    touch "${fastqPass}"
    touch "${fastqFail}"
    touch "${reportHtml}"
    touch "${reportJson}"
    """
}

process fastp_paired_end {
  label 'fastp'

  publishDir "$params.output/intermediates/fastp", mode: 'link'

  input:
    tuple val(meta), path(fastqR1s, arity: '1..*'), path(fastqR2s, arity: '1..*')

  output:
    tuple val(meta), path(fastqPassR1), path(fastqPassR2) , emit: reads_pass, optional: true
    tuple val(meta), path(fastqFail)                      , emit: reads_fail, optional: true
    tuple val(meta), path(reportHtml), path(reportJson)   , emit: report

  shell:
    pairedEnd=true
    basename="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}"

    fastqPassR1="${basename}_R1_pass.fastq.gz"
    fastqPassR2="${basename}_R2_pass.fastq.gz"
    fastqFail="${basename}_fail.fastq.gz"
    reportHtml="${basename}.html"
    reportJson="${basename}.json"
    options=params.fastp.options
    
    template 'fastp_paired_end.sh'

  stub:
    basename="${meta.project.id}_${meta.sample.family_id}_${meta.sample.individual_id}"

    fastqPassR1="${basename}_R1_pass.fastq.gz"
    fastqPassR2="${basename}_R2_pass.fastq.gz"
    fastqFail="${basename}_fail.fastq.gz"
    reportHtml="${basename}.html"
    reportJson="${basename}.json"

    """
    touch "${fastqPassR1}"
    touch "${fastqPassR2}"
    touch "${fastqFail}"
    touch "${reportHtml}"
    touch "${reportJson}"
    """
}
