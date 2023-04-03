nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { scatter } from './modules/utils'
include { findCramIndex } from './modules/cram/utils'
include { samtools_index; samtools_addreplacerg } from './modules/cram/samtools'
include { clair3_call; clair3_call_publish } from './modules/cram/clair3'
include { manta_call; manta_call_publish } from './modules/cram/manta'
include { sniffles2_call; sniffles2_combined_call; sniffles_call_publish } from './modules/cram/sniffles2'
include { vcf } from './vip_vcf'
include { concat_vcf } from './modules/cram/concat_vcf'
include { merge_gvcf } from './modules/vcf/merge_gvcf'

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

    // call short variants, joint per project
    ch_cram_chunked.snv    
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | clair3_call
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats]}
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_snvs }

    ch_vcf_chunked_snvs.done
     | map { meta ->
        def key = [project_id:meta.sample.project_id, chunk:meta.chunk, assembly:meta.sample.assembly]
        def size = meta.sampleSheet.count { sample ->
          sample.project_id == meta.sample.project_id
        }
        [groupKey(key, size), meta]
      }
    | groupTuple
    | map { key, group -> [[project_id:key.project_id, chunk:key.chunk, assembly:key.assembly, samples:group], group.vcf, group.vcf_index]}
    | merge_gvcf
    | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf:vcf, vcf_index:vcfIndex, vcf_stats:vcfStats]}
    | set { ch_vcf_chunked_snvs_merged }

    // publish short variant gvcfs per individual
    ch_vcf_chunked_snvs.publish
      | map { meta -> [groupKey([meta.sample.project_id, meta.sample.family_id, meta.sample.individual_id], meta.chunk.total), meta] }
      | groupTuple
      | map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | clair3_call_publish

   // call SV variants
    ch_cram_chunked.sv  
      | branch {
        meta ->
          manta: meta.sample.sequencing_platform == 'illumina'
          sniffles: meta.sample.sequencing_platform == 'nanopore'
      }
      | set { ch_cram_chunked_sv }

    ch_cram_chunked_sv.manta
      |map {meta -> [meta, meta.sample.cram]}
      |samtools_addreplacerg //to make Manta output the correct sample names
      |map { meta, cram, cramIndex ->
          def key = [project_id:meta.sample.project_id, chunk:meta.chunk, assembly:meta.sample.assembly]
          def size = meta.sampleSheet.count { sample ->
            sample.project_id == meta.sample.project_id
          }
          [groupKey(key, size), [*:meta, sample: [*:meta.sample, manta_cram: cram, manta_cram_index: cramIndex]]]
        }
      | groupTuple
      | map{ key, group -> [[project_id:key.project_id, chunk:key.chunk, assembly:key.assembly, samples:group], group.sample.manta_cram, group.sample.manta_cram_index] }
      | manta_call
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf:vcf, vcf_index:vcfIndex, vcf_stats:vcfStats]}
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_sv_manta }
      
    ch_vcf_chunked_sv_manta.publish
      | map {meta -> [groupKey(meta.project_id, meta.chunk.total), meta]
        }
      | groupTuple
      | map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = metaList.first().findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | manta_call_publish

    ch_cram_chunked_sv.sniffles
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | sniffles2_call
      | map { meta, snf ->
          def key = [project_id:meta.sample.project_id, chunk:meta.chunk, assembly:meta.sample.assembly]
          def size = meta.sampleSheet.count { sample ->
            sample.project_id == meta.sample.project_id
          }
          [groupKey(key, size), [*:meta, sample: [*:meta.sample, snf: snf] ]]
        }
      | groupTuple
      | map{ key, group -> [[project_id:key.project_id,chunk:key.chunk,assembly:key.assembly, samples:group], group.sample.snf] }
      | sniffles2_combined_call
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf:vcf, vcf_index:vcfIndex, vcf_stats:vcfStats]}
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_sv_sniffles_combined }

    ch_vcf_chunked_sv_sniffles_combined.publish
      | map {meta ->
          [groupKey(meta.project_id, meta.chunk.total), meta]
        }
      | groupTuple
      | map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = metaList.first().findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | sniffles_call_publish

    ch_vcf_chunked_sv_sniffles_combined.done.mix(ch_vcf_chunked_sv_manta.done)
    | set { ch_vcf_chunked_svs_done }

    //mix and merge the svs and the snvs
    ch_vcf_chunked_snvs_merged.mix(ch_vcf_chunked_svs_done)
    | map { meta -> [groupKey([project_id: meta.project_id, chunk: meta.chunk],2), meta]}
    | groupTuple(by:[0], size:2)
    //metadata for both sv and snv should be identical except for the vcf related content, just pick the first
    | map{ key, group -> [group[0], group.vcf, group.vcf_index]}
    | concat_vcf
    | flatMap { meta, vcf, vcfIndex, vcfStats -> {meta.samples.collect(entry -> [sample: [*:entry.sample, vcf:vcf, vcf_index:vcfIndex, vcf_stats:vcfStats], chunk: entry.chunk, sampleSheet: entry.sampleSheet]) } }
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
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}
