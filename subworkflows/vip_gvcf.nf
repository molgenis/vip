nextflow.enable.dsl=2

include { validateParams; parseSampleSheet } from '../modules/prototype/cli_gvcf'
include { scatter } from '../modules/prototype/utils'
include { glnexus_merge } from '../modules/prototype/glnexus'
include { bcftools_index; bcftools_view_chunk } from '../modules/prototype/bcftools'
include { vip_vcf } from './vip_vcf'

// FIXME replace hardcoded nrSamples=1 with nrSamples_that_have_data derived from sample sheet
workflow vip_gvcf {
    take: meta
    main:
        meta
            | map { meta -> tuple(groupKey(meta.chunk.index, 1), meta) }
            | groupTuple
            | map { key, group -> tuple([samples: group.collect(meta -> meta.sample), chunk: group.first().chunk], group.collect(meta -> meta.sample.g_vcf)) }
            | glnexus_merge
            | map { meta, vcf, vcfIndex -> [*:meta, vcf: vcf, vcf_index: vcfIndex] }
            | vip_vcf
}

workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)

    // split .g.vcf before calling subworkflow
    Channel.from(sampleSheet)
    | map { sample -> [sample: sample] }
    | flatMap { meta -> scatter(meta) }
    | map { meta -> tuple(meta, meta.sample.g_vcf) }
    | bcftools_index
    | map { meta, gVcfIndex -> [*:meta, sample: [*:meta.sample, g_vcf_index: gVcfIndex]] }
    | map { meta -> tuple(meta, meta.sample.g_vcf, meta.sample.g_vcf_index) }
    | bcftools_view_chunk
    | map { meta, gVcfChunk, gVcfChunkIndex -> [*:meta, sample: [*:meta.sample, g_vcf: gVcfChunk, g_vcf_index: gVcfChunkIndex]] }
    | vip_gvcf
}