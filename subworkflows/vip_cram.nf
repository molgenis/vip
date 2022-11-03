nextflow.enable.dsl=2

include { validateParams; parseSampleSheet } from '../modules/prototype/cli_cram'
include { scatter } from '../modules/prototype/utils'
include { deepvariant_call } from '../modules/prototype/deepvariant'
include { vip_gvcf } from '../subworkflows/vip_gvcf'

// TODO reintroduce trio/duo branching
workflow vip_cram {
    take: meta
    main:
        meta
            | flatMap { meta -> scatter(meta) }
            | map { meta -> tuple(meta, params.reference, params.reference + ".fai", params.reference + ".gzi", meta.sample.cram, meta.sample.cram + ".crai") }
            | deepvariant_call
            | map { meta, gVcf -> [*:meta, sample: [*:meta.sample, g_vcf: gVcf] ] }
            | vip_gvcf
}

workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)

    Channel.from(sampleSheet)
    | map { sample -> [sample: sample] }
    | vip_cram
}