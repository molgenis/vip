nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { findTabixIndex; scatter } from './modules/utils'
include { bcftools_concat; bcftools_index; bcftools_view_chunk_vcf } from './modules/vcf/bcftools'
include { prepare } from './modules/vcf/prepare.nf'
include { preprocess } from './modules/vcf/preprocess.nf'
include { annotate } from './modules/vcf/annotate.nf'
include { classify } from './modules/vcf/classify.nf'
include { filter } from './modules/vcf/filter.nf'
include { inheritance } from './modules/vcf/inheritance'
include { classify_samples } from './modules/vcf/classify_samples'
include { filter_samples } from './modules/vcf/filter_samples'
include { vcf_report } from './modules/vcf/vcf_report'

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
        | map { meta -> [*:meta, vcf_index: meta.vcf_index ?: findTabixIndex(meta.vcf)] }
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

def validateParams() {
  validateCommonParams()
  validateInput()
}

// TODO support .vcf
// TODO support .bcf
def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".vcf.gz") ) exit 1, "parameter 'input' value '${params.input}' is not a .vcf.gz file"
}