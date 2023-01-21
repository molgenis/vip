nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { scatter } from './modules/utils'
include { samtools_index } from './modules/cram/samtools'
include { clair3_call } from './modules/cram/clair3'
include { vcf } from './vip_vcf'
include { merge_gvcf } from './modules/vcf/merge_gvcf'
include { merge_vcf } from './modules/vcf/merge_vcf'

workflow cram {
    take: meta
    main:
        meta
            | flatMap { meta -> scatter(meta) }
            | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
            | clair3_call
            | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, sample: [*:meta.sample, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] ] }
            | set { ch_vcf }

        ch_vcf
          | map { meta ->
              meta = [*:meta, project_id: meta.sample.project_id, assembly: meta.sample.assembly, vcf: meta.sample.vcf, vcf_index: meta.sample.vcf_index, vcf_stats: meta.sample.vcf_stats]
              meta.remove('sample')
              return meta
            }
          | vcf
}

workflow {
    def sampleSheet = parseSampleSheet(params.input)
    validateParams(sampleSheet)

    Channel.from(sampleSheet)
        | map { sample -> [sample: sample, sampleSheet: sampleSheet] }
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
        | cram
}

def validateParams(sampleSheet) {
  validateCommonParams(sampleSheet)
}

def parseSampleSheet(csvFile) {
  def cols = [
    cram: [
      type: "file",
      required: true,
      regex: /.+\.cram/
    ],
    sequencing_platform: [
      type: "string",
      default: 'illumina',
      enum: ['illumina', 'nanopore']
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}

// TODO move to ./modules/cram/utils
def findCramIndex(cram) {
    def cram_index
    if(file(cram + ".crai").exists()) cram_index = cram + ".crai"
    cram_index
}