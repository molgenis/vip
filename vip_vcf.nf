nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { findTabixIndex; scatter; createPedigree } from './modules/utils'
include { bcftools_concat; bcftools_index; bcftools_view_chunk_vcf } from './modules/vcf/bcftools'
include { prepare } from './modules/vcf/prepare.nf'
include { preprocess } from './modules/vcf/preprocess.nf'
include { annotate } from './modules/vcf/annotate.nf'
include { classify } from './modules/vcf/classify.nf'
include { filter } from './modules/vcf/filter.nf'
include { inheritance } from './modules/vcf/inheritance'
include { classify_samples } from './modules/vcf/classify_samples'
include { filter_samples } from './modules/vcf/filter_samples'
include { report } from './modules/vcf/report'
include { nrRecords } from './modules/vcf/utils'

workflow vcf {
    take: meta
    main:
        meta
            | map { meta -> tuple(meta, meta.vcf, meta.vcf_index) }
            | prepare
            | flatMap { meta, vcf, vcfCsi, vcfStats -> nrRecords(vcfStats) > 0 ? [tuple(meta, vcf, vcfCsi)] : [] }
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
            | map { metaList -> tuple([*:metaList[0], chunk: null], metaList.collect { meta -> meta.vcf }) }
            | bcftools_concat
            | set { ch_concat }
                
        ch_concat
            | report
}

workflow {
    validateParams()
    
    def sampleSheet = parseSampleSheet(params.input)
    def probands = sampleSheet.findAll{ sample -> sample.proband }.collect{ sample -> [family_id:sample.family_id, individual_id:sample.individual_id] }
    def hpo_ids = sampleSheet.collectMany { sample -> sample.hpo_ids }.unique()

    Channel.from(sampleSheet)
        | map { sample -> tuple(groupKey(sample.vcf, sampleSheet.count{ it.vcf == sample.vcf }), sample) }
        | groupTuple
        | map { key, group -> 
            def aSample = group.first()
            def vcf = aSample.vcf
            def vcf_index = aSample.vcf_index ?: findTabixIndex(vcf)
            [vcf: vcf, vcf_index: vcf_index, sampleSheet: sampleSheet, probands: probands, hpo_ids: hpo_ids]
          }
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
        | vcf
}

def validateParams() {
  validateCommonParams()
}

def parseSampleSheet(csvFile) {
  def cols = [
    vcf: [
      type: "file",
      required: true,
      regex: /.+\.vcf\.gz/
    ],
    vcf_index: [
      type: "file",
      regex: /.+\.vcf\.gz\.(csi|tbi)/
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}