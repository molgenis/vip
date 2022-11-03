nextflow.enable.dsl=2

include { validateParams; parseSampleSheet } from '../modules/prototype/cli_fastq'
include { minimap2_align } from '../modules/prototype/minimap2'
include { vip_cram } from '../subworkflows/vip_cram'

workflow vip_fastq {
    take: meta
    main:
        meta
            | map { meta -> tuple(meta, meta.sample.fastq_r1, meta.sample.fastq_r2, params.reference, params.reference + ".fai", params.reference + ".gzi", params.reference + ".mmi") }
            | minimap2_align
            | map { meta, cram, cramIndex -> [*:meta, sample: [*:meta.sample, cram: cram, cram_index: cramIndex] ] }
            | vip_cram
}

workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)

    Channel.from(sampleSheet)
    | map { sample -> [sample: sample]}
    | vip_fastq
}