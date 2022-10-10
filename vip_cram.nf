nextflow.enable.dsl=2

include { validateParams; parseSampleSheet } from './modules/prototype/cli_cram'
include { findCramIndex; scatter } from './modules/prototype/utils'
include { samtools_index } from './modules/prototype/samtools'
include { deepvariant_call } from './modules/prototype/deepvariant'
include { vip_gvcf } from './vip_gvcf'

// TODO reintroduce trio/duo branching
workflow vip_cram {
    take: meta
    main:
        meta
            | flatMap { meta -> scatter(meta) }
            | map { meta -> tuple(meta, meta.sample.cram, meta.sample.cram_index) }
            | deepvariant_call
            | map { meta, gVcf -> [*:meta, sample: [*:meta.sample, g_vcf: gVcf] ] }
            | vip_gvcf
}

workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)

    Channel.from(sampleSheet)
        | map { sample -> [sample: sample] }
        | map { meta -> [*:meta, sample: [*:meta.sample, cram_index: meta.sample.cram_index ?: findCramIndex(meta.sample.cram)]] }
        | branch { meta ->
            index: meta.sample.cram_index == null
            ready: true
        }
        | set { ch_sample }

    ch_sample.index
        | map { meta -> tuple(meta, meta.sample.cram) }
        | samtools_index
        | map { meta, cramIndex -> [*:meta, sample: [*:meta.sample, cram_index: cramIndex]] }
        | set { ch_sample_indexed }

    ch_sample_indexed.mix(ch_sample.ready)
        | vip_cram
}