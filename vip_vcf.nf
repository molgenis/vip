nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { findIndex; scatter; createPedigree } from './modules/utils'
include { convert } from './modules/vcf/convert'
include { index } from './modules/vcf/index'
include { merge } from './modules/vcf/merge'
include { split } from './modules/vcf/split'
include { prepare } from './modules/vcf/prepare'
include { preprocess } from './modules/vcf/preprocess'
include { annotate } from './modules/vcf/annotate'
include { classify } from './modules/vcf/classify'
include { filter } from './modules/vcf/filter'
include { inheritance } from './modules/vcf/inheritance'
include { classify_samples } from './modules/vcf/classify_samples'
include { filter_samples } from './modules/vcf/filter_samples'
include { concat } from './modules/vcf/concat'
include { report } from './modules/vcf/report'
include { nrRecords; getProbands; getHpoIds } from './modules/vcf/utils'

workflow vcf {
    take: meta
    main:
        meta
            | map { meta -> tuple([*:meta, probands: getProbands(meta.sampleSheet), hpo_ids: getHpoIds(meta.sampleSheet) ], meta.vcf, meta.vcf_index) }
            | prepare
            | flatMap { meta, vcf, vcfCsi, vcfStats -> nrRecords(vcfStats) > 0 ? [tuple(meta, vcf, vcfCsi)] : [] } // FIXME chunk.total invalid after operation
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
            | map { meta -> [meta.project_id, meta] } // TODO use 'groupKey(meta.project_id, meta.sampleSheet.size() * meta.chunk.total)'. currently doesn't work because chunk.total is invalid (see FIXME)
            | groupTuple
            | map { key, metaList -> 
                def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
                def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'chunk' }
                [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index } ]
              }
            | concat
            | set { ch_concat }
                
        ch_concat
            | report
}

workflow {
    validateParams()
    
    def sampleSheet = parseSampleSheet(params.input)

    // emit unique vcfs with corresponding sample sheet rows
    Channel.from(sampleSheet)
        | map { sample -> [groupKey(sample.vcf, sampleSheet.count{ it.vcf == sample.vcf }), sample] }
        | groupTuple
        | map { key, group -> [vcf: group.first().vcf, vcf_index: findIndex(key), sampleSheet: group] }
        | branch { meta ->
            convert: !(meta.vcf ==~ /.+\.vcf\.gz/)
            index:   meta.vcf_index == null
            ready:   true
          }
        | set { ch_vcfs }
    
    // preprocess vcfs
    ch_vcfs.convert
        | map { meta -> [meta, meta.vcf] }
        | convert
        | map { meta, vcf, vcf_index -> [*:meta, vcf: vcf, vcf_index: vcf_index] }
        | set { ch_vcfs_converted }

    ch_vcfs.index
        | map { meta -> [meta, meta.vcf] }
        | index
        | map { meta, vcf_index -> [*:meta, vcf_index: vcf_index] }
        | set { ch_vcfs_indexed }

    // group vcfs per project
    ch_vcfs.ready.mix(ch_vcfs_converted, ch_vcfs_indexed)
        | flatMap { meta -> meta.sampleSheet.collect { sample -> [*:meta, sample: sample].findAll { it.key != 'sampleSheet' } } }
        | map { meta -> [groupKey(meta.sample.project_id, sampleSheet.count{ it.project_id == meta.sample.project_id }), meta] }
        | groupTuple
        | map { key, group -> [project_id: group.first().sample.project_id, sampleSheet: group] }
        | branch { meta ->
            merge: meta.sampleSheet.collect{ it.vcf }.unique().size() > 1
            ready: true
          }
        | set { ch_project_vcfs }

    // merge unique project vcfs
    ch_project_vcfs.merge
        | map { meta -> [ meta, meta.sampleSheet.collect{ it.vcf }.unique(), meta.sampleSheet.collect{ it.vcf_index }.unique() ] }
        | merge
        | map { meta, vcf, vcfIndex -> [*:meta, vcf: vcf, vcf_index: vcfIndex, sampleSheet: meta.sampleSheet.collect { it.sample }] }
        | set { ch_project_vcfs_merged }

    ch_project_vcfs.ready
        | map { meta -> [ *:meta, vcf: meta.sampleSheet.first().vcf, vcf_index: meta.sampleSheet.first().vcf_index, sampleSheet: meta.sampleSheet.collect { it.sample } ] }
        | mix(ch_project_vcfs_merged)
        | set { ch_inputs }

    ch_inputs
        | flatMap { meta -> scatter(meta) }
        | map { meta -> tuple(meta, meta.vcf, meta.vcf_index) }
        | split
        | map { meta, vcfChunk, vcfChunkIndex -> [*:meta, vcf: vcfChunk, vcf_index: vcfChunkIndex] }
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
      regex: /.+(?:\.bcf|\.bcf.gz|\.vcf|\.vcf\.gz)/
    ],
    cram: [
      type: "file",
      regex: /.+(?:\.bam|\.cram)/
    ],
  ]
  return parseCommonSampleSheet(csvFile, cols)
}