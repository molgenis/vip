nextflow.enable.dsl=2

include { vcf_report } from '../modules/prototype/vcf_report'

workflow vcf2html {
    take: meta
    main:
        meta
            | map { meta -> tuple(meta, meta.vcf, meta.reference.fasta, meta.reference.fai, meta.reference.gzi) }
            | vcf_report
}

workflow {
    def vcf = params.vcf
    def fasta = params.reference
    def fai = fasta + ".fai"
    def gzi = fasta + ".gzi"

    vcf2html( channel.from( [vcf: vcf, reference: [fasta: fasta, fai: fai, gzi: gzi]] ) )
}