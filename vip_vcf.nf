nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { findIndex; scatter; createPedigree } from './modules/utils'
include { convert } from './modules/vcf/convert'
include { index } from './modules/vcf/index'
include { merge } from './modules/vcf/merge'
include { split } from './modules/vcf/split'
include { normalize } from './modules/vcf/normalize'
include { annotate } from './modules/vcf/annotate'
include { classify } from './modules/vcf/classify'
include { filter } from './modules/vcf/filter'
include { inheritance } from './modules/vcf/inheritance'
include { classify_samples } from './modules/vcf/classify_samples'
include { filter_samples } from './modules/vcf/filter_samples'
include { concat } from './modules/vcf/concat'
include { slice } from './modules/vcf/slice'
include { report } from './modules/vcf/report'
include { nrRecords; getProbands; getHpoIds } from './modules/vcf/utils'

workflow vcf {
    take: meta
    main:
        meta
            | map { meta -> tuple([*:meta, probands: getProbands(meta.sampleSheet), hpo_ids: getHpoIds(meta.sampleSheet) ], meta.vcf, meta.vcf_index, meta.vcf_stats) }
            | branch { meta, vcf, vcfIndex, vcfStats ->
                process: nrRecords(vcfStats) > 0
                empty: true
              }
            | set { ch_inputs }

        ch_inputs.process
            | normalize
            | set { ch_normalized }

        ch_normalized
            | annotate
            | set { ch_annotated }

        ch_annotated
            | classify
            | set { ch_classified }

        ch_classified
            | filter
            | branch { meta, vcf, vcfIndex, vcfStats ->
                process: nrRecords(vcfStats) > 0
                empty: true
              }
            | set { ch_filtered }

        ch_filtered.process
            | inheritance
            | set { ch_inheritanced }

        ch_inheritanced
            | classify_samples
            | set { ch_classified_samples }

        ch_classified_samples
            | filter_samples
            | branch { meta, vcf, vcfIndex, vcfStats ->
                process: nrRecords(vcfStats) > 0
                empty: true
              }
            | set { ch_filtered_samples }

        ch_filtered_samples.process.mix(ch_inputs.empty, ch_filtered.empty, ch_filtered_samples.empty)
            | set { ch_outputs }

        ch_outputs
            | map { meta, vcf, vcfCsi, vcfStats -> [*:meta, vcf: vcf, vcf_index: vcfCsi, vcf_stats: vcfStats] }
            | map { meta -> [groupKey(meta.project_id, meta.chunk.total), meta] }
            | groupTuple
            | map { key, metaList -> 
                def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
                def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'chunk' }
                [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index } ]
              }
            | concat
            | map { meta, vcf, vcfCsi -> [*:meta, vcf: vcf, vcf_index: vcfCsi] }
            | branch { meta ->
                slice: meta.sampleSheet.any{ sample -> sample.cram != null }
                ready: true
              }
            | set { ch_concated }
     
        ch_concated.slice
            | flatMap { meta -> meta.sampleSheet.findAll{ sample -> sample.cram != null }.collect{ sample -> [*:meta, sample: sample] } }
            | map { meta -> tuple(meta, meta.vcf, meta.vcf_index, meta.sample.cram) }
            | slice
            | map { meta, cram -> [*:meta, cram: cram] }
            | map { meta -> [groupKey(meta.project_id, meta.sampleSheet.count{ sample -> sample.cram != null }), meta] }
            | groupTuple
            | map { key, metaList -> 
                def meta = [*:metaList.first()].findAll { it.key != 'sample' && it.key != 'cram' }
                [*:meta, crams: metaList.collect { [family_id: it.sample.family_id, individual_id: it.sample.individual_id, cram: it.cram] } ]
              }
            | set { ch_sliced }

        ch_sliced.mix(ch_concated.ready)
            | map { meta -> [meta, meta.vcf, meta.vcf_index, meta.crams ? meta.crams.collect { it.cram } : []] }
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
        | map { meta, vcfChunk, vcfChunkIndex, vcfChunkStats -> [*:meta, vcf: vcfChunk, vcf_index: vcfChunkIndex, vcf_stats: vcfChunkStats] }
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