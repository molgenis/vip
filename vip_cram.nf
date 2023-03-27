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
include { merge_gvcf } from './modules/cram/merge_gvcf'

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
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_snvs }


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
      |map { meta, cram, cramIndex -> [*:meta, sample: [*:meta.sample, manta_cram: cram, manta_cram_index: cramIndex]]}
      |map { meta ->
          def key = [meta.sample.project_id, meta.chunk, meta.sample.assembly]
          def size = meta.sampleSheet.count { sample ->
            sample.project_id == meta.sample.project_id
          }
          [groupKey(key, size), meta]
        }
      | groupTuple
      | map { key, group -> [key, group, group.sample.manta_cram, group.sample.manta_cram_index] }
      | manta_call
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_sv_manta }

    ch_cram_chunked_sv.sniffles
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | sniffles2_call
      | map { meta, snf -> [*:meta, sample: [*:meta.sample, snf: snf] ] }
      | set { ch_vcf_chunked_sv_sniffles }

    ch_vcf_chunked_sv_sniffles
      |map { meta ->
          def key = [meta.sample.project_id, meta.chunk, meta.sample.assembly]
          def size = meta.sampleSheet.count { sample ->
            sample.project_id == meta.sample.project_id
          }
          [groupKey(key, size), meta]
        }
      | groupTuple
      //sniffles2_combined_call takes meta, project_id, chunk, assembly, snf[]
      | map{ key, group -> [key, group, key[0], key[1], key[2], group.sample.snf] }//FIXME: get arguments from key
      | sniffles2_combined_call
      | multiMap { it -> done: publish: it }
      | set { ch_vcf_chunked_sv_sniffles_combined }

    ch_vcf_chunked_sv_manta.publish
      /**| map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | manta_call_publish**/

      ch_vcf_chunked_sv_sniffles_combined.publish
      /**| map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | sniffles_call_publish**/
    
    ch_vcf_chunked_snvs.publish
      /**| map { key, metaList -> 
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | clair3_call_publish**/

    ch_vcf_chunked_snvs.done
    | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, sample: [*:meta.sample, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] ] }
    | map { meta ->
        def key = [meta.sample.project_id, meta.chunk, meta.sample.assembly]
        def size = meta.sampleSheet.count { sample ->
          sample.project_id == meta.sample.project_id
        }
        [groupKey(key, size), meta]
      }
    | groupTuple
    | map { key, group -> [key: key, meta: group, gVcfs:group.sample.vcf, gVcfIndexes: group.sample.vcf_index] }
    | merge_gvcf
    | set { ch_vcf_chunked_snvs_merged }

    ch_vcf_chunked_sv_sniffles_combined.done.mix(ch_vcf_chunked_sv_manta.done)
    | set { ch_vcf_chunked_svs_done }

    ch_vcf_chunked_snvs_merged.mix(ch_vcf_chunked_svs_done)
    | groupTuple(by:[0], size:2)
    | map{ group -> [meta: group, vcf: group[2], vcf_index: group[3]]}
    | concat_vcf
    | flatMap { meta, vcf, vcfIndex, vcfStats -> {meta.collect(entry -> [sample: [*:entry.sample, vcf:vcf, vcf_index:vcfIndex, vcf_stats:vcfStats], chunk: entry.chunk, sampleSheet: entry.sampleSheet]) } }
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
