nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { scatter } from './modules/utils'
include { findCramIndex } from './modules/cram/utils'
include { samtools_index } from './modules/cram/samtools'
include { clair3_call; clair3_call_publish } from './modules/cram/clair3'
include { manta_call; manta_call_publish } from './modules/cram/manta'
include { sniffles2_call; sniffles_call_publish } from './modules/cram/sniffles2'
include { vcf } from './vip_vcf'
include { concat_vcf } from './modules/cram/concat_vcf'

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

    // call short variants
    ch_cram_chunked.snv    
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | clair3_call
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_snvs }

    // continue with vcf workflow

   // call SV variants
    ch_cram_chunked.sv  
      | branch {
        meta ->
          manta: meta.sample.sequencing_platform == 'illumina'
          sniffles: meta.sample.sequencing_platform == 'nanopore'
      }
      | set { ch_cram_chunked_sv }

    ch_cram_chunked_sv.manta
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | manta_call
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_sv_manta }

    ch_cram_chunked_sv.sniffles
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | sniffles2_call
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_sv_sniffles }

    ch_vcf_chunked_sv_manta.publish
      | map { meta, vcf, vcfCsi, vcfStats -> [groupKey([meta.sample.project_id, meta.sample.family_id, meta.sample.individual_id], meta.chunk.total), [*:meta, vcf: vcf, vcf_index: vcfCsi, vcf_stats: vcfStats]] }
      | groupTuple
      | map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | manta_call_publish

      ch_vcf_chunked_sv_sniffles.publish
      | map { meta, vcf, vcfCsi, vcfStats -> [groupKey([meta.sample.project_id, meta.sample.family_id, meta.sample.individual_id], meta.chunk.total), [*:meta, vcf: vcf, vcf_index: vcfCsi, vcf_stats: vcfStats]] }
      | groupTuple
      | map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | sniffles_call_publish

    ch_vcf_chunked_sv_manta.done.mix(ch_vcf_chunked_sv_sniffles.done)
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, sample: [*:meta.sample, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] ] }
      | map { meta -> [meta.sample.cram, meta.chunk.index, meta.sample.project_id, meta] }
      | set { ch_vcf_chunked_svs } 

    ch_vcf_chunked_snvs.publish
      | map { meta, vcf, vcfCsi, vcfStats -> [groupKey([meta.sample.project_id, meta.sample.family_id, meta.sample.individual_id], meta.chunk.total), [*:meta, vcf: vcf, vcf_index: vcfCsi, vcf_stats: vcfStats]] }
      | groupTuple
      | map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | clair3_call_publish

    ch_vcf_chunked_snvs.done
    | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, sample: [*:meta.sample, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] ] }
    | map { meta -> [meta.sample.cram, meta.chunk.index, meta.sample.project_id, meta] }
    | set { ch_vcf_chunked_snvs_done }

    ch_vcf_chunked_snvs_done.mix(ch_vcf_chunked_svs)
      | groupTuple(by:[0,1,2], size:2)
      //grouped[0], [1] and [2] are the cram,index and project_id; the fields we use to group on. Size should be 2: a sv file and a snv file.
      | map { grouped -> [grouped[3], [grouped[3][0].sample.vcf, grouped[3][1].sample.vcf],[grouped[3][0].sample.vcf_index, grouped[3][1].sample.vcf_index]]}
      | concat_vcf
      //both metadata's in the group are the same, except for the unmerged vcf, we pick the first for the metadata to continue with
      | map { nested_meta, vcf, vcfIndex, vcfStats -> [*:nested_meta[0], sample: [*:nested_meta[0].sample, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats]] }
      | vcf
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
    ],
    sequencing_method: [
      type: "string",
      default: { 'WGS' },
      enum: ['WES', 'WGS']
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}
