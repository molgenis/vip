nextflow.enable.dsl=2

include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { scatter } from './modules/utils'
include { findCramIndex } from './modules/cram/utils'
include { samtools_index; samtools_addreplacerg } from './modules/cram/samtools'
include { clair3_call; clair3_call_publish } from './modules/cram/clair3'
include { expansionhunter_call } from './modules/cram/expansionhunter'
include { manta_call; manta_call_publish } from './modules/cram/manta'
include { cutesv_call; cutesv_call_publish; cutesv_merge } from './modules/cram/cutesv'
include { call_publish } from './modules/cram/publish'
include { vcf; validateVcfParams } from './vip_vcf'
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

    // forward crams to a channel that works on cram chunks and a channel that works on the whole cram
    ch_cram_indexed.mix(ch_cram.ready)
      | multiMap { it -> chunk: whole: it }
      | set { ch_cram_process }

    // do stuff with unchunked cram
    ch_cram_process.whole
      | multiMap { it -> str: it }
      | set { ch_cram_process_whole }

    // select channel for short tandem repeat detection based on the sequencing platform
    ch_cram_process_whole.str
      | filter { params.cram.detect_str == true }
      | branch { meta ->
          short_read: meta.sample.sequencing_platform == 'illumina'
        }
      | set { ch_cram_detect_str }

    // short tandem repeat detection onrun ExpansionHunter
    ch_cram_detect_str.short_read
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | expansionhunter_call

    // do stuff with chunked cram
    ch_cram_process.chunk
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
        def key = [project_id:meta.sample.project_id, chunk:meta.chunk, assembly:meta.sample.assembly, sequencing_platform:meta.sample.sequencing_platform]
        def size = meta.sampleSheet.count { sample ->
          sample.project_id == meta.sample.project_id
        }
        [groupKey(key, size), meta]
      }
    | groupTuple
    | map { key, group -> [[project_id:key.project_id, chunk:key.chunk, assembly:key.assembly, samples:group, sequencing_platform:key.sequencing_platform], group.vcf, group.vcf_index]}
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
          cutesv: meta.sample.sequencing_platform == 'nanopore' || meta.sample.sequencing_platform == 'pacbio_hifi'
      }
      | set { ch_cram_chunked_sv }

    // call SV variants: Manta
    ch_cram_chunked_sv.manta
      | map {meta -> [meta, meta.sample.cram]}
      | samtools_addreplacerg //to make Manta output the correct sample names
      | map { meta, cram, cramIndex ->
          def key = [project_id:meta.sample.project_id, chunk:meta.chunk, assembly:meta.sample.assembly]
          def size = meta.sampleSheet.count { sample ->
            sample.project_id == meta.sample.project_id
          }
          [groupKey(key, size), [*:meta, sample: [*:meta.sample, manta_cram: cram, manta_cram_index: cramIndex]]]
        }
      | groupTuple
      | map{ key, group -> [[project_id:key.project_id, chunk:key.chunk, assembly:key.assembly, samples:group], group.sample.manta_cram, group.sample.manta_cram_index] }
      | manta_call
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf:vcf, vcf_index:vcfIndex, vcf_stats:vcfStats, sequencing_platform:"illumina"]}
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

    // call SV variants: cuteSV
    ch_cram_chunked_sv.cutesv
      | map { meta -> [meta, meta.sample.cram, meta.sample.cram_index] }
      | cutesv_call
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats]}
      // Only publish the intermediate result until this issues:
      // - https://github.com/tjiangHIT/cuteSV/issues/124
      // - calls outside the regions of the bed file
      // are resolved
      | set { ch_vcf_chunked_sv_cutesv_publish }

    ch_vcf_chunked_sv_cutesv_publish
      | map { meta -> [groupKey([meta.sample.project_id, meta.sample.family_id, meta.sample.individual_id], meta.chunk.total), meta] }
      | groupTuple
      | map { key, metaList ->
          def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
          def meta = [*:sortedMetaList.first()].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
          [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
        }
      | cutesv_call_publish

    //mix and merge the svs and the snvs
    ch_vcf_chunked_snvs_merged.mix(ch_vcf_chunked_sv_manta.done)
    //Group size 2 for Illumina (SV + SNV), size 1 for Nanopore/PacBio (SNV only)
    | map { meta -> [groupKey([project_id: meta.project_id, chunk: meta.chunk],meta.sequencing_platform=="illumina"?2:1), meta]}
    | groupTuple
    //metadata for both sv and snv should be identical except for the vcf related content, just pick the first
    | map{ key, group -> [group[0], group.vcf, group.vcf_index]}
    | concat_vcf
    | multiMap { it -> done: publish: it }
    | set { ch_cram_output }

    ch_cram_output.publish
    | map {meta, vcf, vcfIndex, vcfStats ->
        [groupKey(meta.project_id, meta.chunk.total), [*:meta, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats]]
      }
    | groupTuple
    | map { key, metaList -> 
        def sortedMetaList = metaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
        def meta = metaList.first().findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
        [meta, sortedMetaList.collect { it.vcf }, sortedMetaList.collect { it.vcf_index }]
      }
    | call_publish

    ch_cram_output.done
    | flatMap { meta, vcf, vcfIndex, vcfStats -> {meta.samples.collect(entry -> [sample: [*:entry.sample, vcf:vcf, vcf_index:vcfIndex, vcf_stats:vcfStats], chunk: entry.chunk, sampleSheet: entry.sampleSheet]) } }
    | vcf
}

workflow {
  def sampleSheet = parseSampleSheet(params.input)
  def assemblies = getAssemblies(sampleSheet)
  validateCramParams(assemblies)

  // create sample channel, detect cram index and continue with cram workflow   
  Channel.from(sampleSheet)
    | map { sample -> [sample: [*:sample, cram_index: findCramIndex(sample.cram)], sampleSheet: sampleSheet] }
    | cram
}

def validateCramParams(assemblies) {
  validateVcfParams(assemblies)

  def detectStr = params.cram.detect_str
  if (!(detectStr ==~ /true|false/))  exit 1, "parameter 'cram.detect_str' value '${detectStr}' is invalid. allowed values are [true, false]"

  // expansion hunter
  def expansionhunterAligner = params.cram.expansionhunter.aligner
  if (!(expansionhunterAligner ==~ /dag-aligner|path-aligner/))  exit 1, "parameter 'cram.expansionhunter.aligner' value '${expansionhunterAligner}' is invalid. allowed values are [dag-aligner, path-aligner]"

  def expansionhunterAnalysisMode = params.cram.expansionhunter.analysis_mode
  if (!(expansionhunterAnalysisMode ==~ /seeking|streaming/))  exit 1, "parameter 'cram.expansionhunter.analysis_mode' value '${expansionhunterAnalysisMode}' is invalid. allowed values are [seeking, streaming]"

  def expansionhunterLogLevel = params.cram.expansionhunter.log_level
  if (!(expansionhunterLogLevel ==~ /trace|debug|info|warn|error/))  exit 1, "parameter 'cram.expansionhunter.log_level' value '${expansionhunterLogLevel}' is invalid. allowed values are [trace, debug, info, warn, error]"

  assemblies.each { assembly ->
    def expansionhunterVariantCatalog = params.cram.expansionhunter[assembly].variant_catalog
    if(!file(expansionhunterVariantCatalog).exists() )   exit 1, "parameter 'cram.expansionhunter.${assembly}.variant_catalog' value '${expansionhunterVariantCatalog}' does not exist"
  }
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
      enum: ['illumina', 'nanopore', 'pacbio_hifi']
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}
