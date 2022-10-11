process vcf_report_create {
  publishDir "$params.output", mode: 'link'

  input:
    path(vcf)
  output:
    path(html)
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
