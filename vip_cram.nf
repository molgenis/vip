nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { scatter } from './modules/utils'
include { findCramIndex } from './modules/cram/utils'
include { samtools_index } from './modules/cram/samtools'
include { clair3_call } from './modules/cram/clair3'
include { manta_call } from './modules/cram/manta'
include { vcf } from './vip_vcf'
include { merge_vcf } from './modules/vcf/merge_vcf'

workflow cram {
  take: meta
  main:
    // split channel in crams with and without index
    meta
      | branch { meta ->
          index: meta.sample.cram_index == null
          ready: true
      }
      | set { ch_cram }

    // index crams
    ch_cram.index
      | map { meta -> tuple(meta, meta.sample.cram) }
      | samtools_index
      | map { meta, cramIndex -> [*:meta, sample: [*:meta.sample, cram_index: cramIndex]] }
      | set { ch_cram_indexed }

    // determine chunks for indexed crams
    ch_cram_indexed.mix(ch_cram.ready)
      | flatMap { meta -> scatter(meta) }
      | multiMap { it -> snv: sv: it }
      | set { ch_cram_chunked }

    // call regular variants
    ch_cram_chunked.snv    
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | clair3_call
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, sample: [*:meta.sample, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] ] }
      | map { meta -> [meta.sample.cram, meta.chunk.index, meta] }
      | set { ch_vcf_chunked }

    // call SV variants
    ch_cram_chunked.sv   
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | manta_call
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, sample: [*:meta.sample, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] ] }
      | map { meta -> [meta.sample.cram, meta.chunk.index, meta] }
      | set { ch_vcf_chunked_sv }

    // continue with vcf workflow
    ch_vcf_chunked.mix(ch_vcf_chunked_sv)
    | groupTuple(by:[0,1], size:2)
    | map { grouped -> [grouped[2][0], [grouped[2][0].sample.vcf, grouped[2][1].sample.vcf],[grouped[2][0].sample.vcf_index, grouped[2][1].sample.vcf_index]]}
    | merge_vcf
    | view
    // merge SV and SNV vcf
    //| map { grouped, vcf, vcfIndex, vcfStats -> [*:grouped[0], sample: [*:meta.sample, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] ] }
    // | view
    // | vcf
}

workflow {
  def sampleSheet = parseSampleSheet(params.input)
  validateParams(sampleSheet)

  // create sample channel, detect cram index and continue with cram workflow   
  Channel.from(sampleSheet)
    | map { sample -> [sample: [*:sample, cram_index: findCramIndex(sample.cram)], sampleSheet: sampleSheet] }
    | cram
}

def validateParams(sampleSheet) {
  def assemblies = getAssemblies(sampleSheet)
  validateCommonParams(assemblies)
}

def parseSampleSheet(csvFile) {
  def cols = [
    cram: [
      type: "file",
      required: true,
      regex: /.+\.(cram|bam)/
    ],
    sequencing_platform: [
      type: "string",
      default: { 'illumina' },
      enum: ['illumina', 'nanopore']
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}
