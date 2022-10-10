nextflow.enable.dsl=2

include { validateParams } from './modules/prototype/cli_vcf'
include { findVcfIndex; scatter } from './modules/prototype/utils'
include { bcftools_concat; bcftools_index; bcftools_view_chunk_vcf } from './modules/prototype/bcftools'
include { prepare } from './modules/prepare.nf'
include { preprocess } from './modules/preprocess.nf'
include { annotate } from './modules/annotate.nf'
include { classify } from './modules/classify.nf'
include { filter } from './modules/filter.nf'
include { inheritance } from './modules/inheritance'
include { classify_samples } from './modules/classify_samples'
include { filter_samples } from './modules/filter_samples'
include { vcf_report } from './modules/prototype/vcf_report'

workflow vip_vcf {
    take: meta
    main:
        meta
            | map { meta -> tuple(meta, meta.vcf, meta.vcf_index) }
            | prepare
            | set { ch_prepared }

        ch_prepared
            | preprocess
            | set { ch_preprocessed }

        ch_preprocessed
            | annotate
            | set { ch_annotated }

        ch_annotated
            | classify
            | set { ch_classified }

        ch_classified
            | filter
            | set { ch_filtered }

        ch_filtered
            | inheritance
            | set { ch_inheritanced }

        ch_inheritanced
            | classify_samples
            | set { ch_classified_samples }

        ch_classified_samples
            | filter_samples
            | set { ch_filtered_samples }

        ch_filtered_samples
            | map { meta, vcf, vcfCsi -> [*:meta, vcf: vcf, vcf_index: vcfCsi] }
            | collect(sort: { metaLeft, metaRight -> metaRight.chunk.index <=> metaLeft.chunk.index })
            | map { metaList -> tuple([], metaList.collect { meta -> meta.vcf }) }
            | bcftools_concat
            | set { ch_concat }
                
        ch_concat
            | vcf_report
}

workflow {
    validateParams()
    
    def vcf = params.input
        
    Channel.from([vcf: vcf])
        | map { meta -> [*:meta, vcf_index: meta.vcf_index ?: findVcfIndex(meta.vcf)] }
        | branch { meta ->
            index: meta.vcf_index == null
            ready: true
          }
        | set { ch_input }
    
    ch_input.index
        | map { meta -> tuple(meta, meta.vcf) }
        | bcftools_index
        | map { meta, vcfIndex -> [*:meta, vcf_index: vcfIndex] }
        | set { ch_input_indexed }
    
    ch_input_indexed.mix(ch_input.ready)
        | flatMap { meta -> scatter(meta) }
        | map { meta -> tuple(meta, meta.vcf, meta.vcf_index) }
        | bcftools_view_chunk_vcf
        | map { meta, vcfChunk, vcfChunkIndex -> [*:meta, vcf: vcfChunk, vcf_index: vcfChunkIndex] }
        | set { ch_input_chunked }
    
    ch_input_chunked
        | vip_vcf
}
