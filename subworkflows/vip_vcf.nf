nextflow.enable.dsl=2

include { vcf_report } from '../modules/prototype/vcf_report'

//TODO merge
//TODO add vip
workflow vip_vcf {
    take: meta
    main:
        meta
            | map { meta -> tuple(meta, meta.vcf, meta.vcf_index, params.reference, params.reference + ".fai", params.reference + ".gzi") }
            | vcf_report
}

// FIXME cli
workflow {
    // TODO parameter validation
    def vcf = params.vcf
    def fasta = params.reference
    def fai = fasta + ".fai"
    def gzi = fasta + ".gzi"

    vip_vcf( channel.from( [vcf: vcf, reference: [fasta: fasta, fai: fai, gzi: gzi]] ) )
}