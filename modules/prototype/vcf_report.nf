// FIXME reintroduce --reference (which can result in 'the input sequence contains invalid base calls like: :' error)
process vcf_report {
  publishDir "$params.output", mode: 'link'

  input:
    tuple val(meta), path(vcf), path(vcf_index)
  output:
    tuple val(meta), path(html)
  script:
    html="vip_report.html"
    """
    ${CMD_VCFREPORT} java \
    -Djava.io.tmpdir=\"${TMPDIR}\" \
    -XX:ParallelGCThreads=2 \
    -jar /opt/vcf-report/lib/vcf-report.jar \
    --input "${vcf}" \
    --output "${html}"
    """
}
