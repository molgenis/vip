nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { findVcfIndex; createPedigree } from './modules/utils'
include { findCramIndex } from './modules/cram/utils'
include { samtools_index } from './modules/cram/samtools'
include { convert } from './modules/vcf/convert'
include { index } from './modules/vcf/index'
include { stats } from './modules/vcf/stats'
include { merge_vcf } from './modules/vcf/merge_vcf'
include { merge_gvcf } from './modules/vcf/merge_gvcf'
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
include { nrRecords; getProbands; getHpoIds; scatter; getVcfRegex; isGVcf } from './modules/vcf/utils'

/*
 * input:
 *   [
 *     sample: [],      
 *     sampleSheet: [],
 *     chunk: []        <-- optional, if defined then meta.chunk.total must be equal for all channel items
 *   ]
 */
workflow vcf {
    take: meta
    main:
      // emit unique vcfs with corresponding sample sheet rows
      meta
        | map { meta ->
            def key = [meta.sample.vcf, meta.sample.vcf_index, meta.sample.vcf_stats]
            def size = meta.sampleSheet.count { sample ->
              sample.vcf == meta.sample.vcf &&
              sample.vcf_index == meta.sample.vcf_index &&
              sample.vcf_stats == meta.sample.vcf_stats
            } * (meta.chunk?.total ?: 1)
            [groupKey(key, size), meta]
          }
        | groupTuple
        | map { key, group -> [vcf: key[0], vcf_index: key[1], vcf_stats: key[2], metaList: group] }
        | branch { meta ->
            convert: !(meta.vcf ==~ /.+\.vcf\.gz/)
            index:   meta.vcf_index == null
            stats:   meta.vcf_stats == null
            ready:   true
          }
        | set { ch_vcfs }
    
      // preprocess vcfs
      ch_vcfs.convert
        | map { meta -> [meta, meta.vcf] }
        | convert
        | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] }
        | set { ch_vcfs_converted }

      ch_vcfs.index
        | map { meta -> [meta, meta.vcf] }
        | index
        | map { meta, vcfIndex, vcfStats -> [*:meta, vcf_index: vcfIndex, vcf_stats: vcfStats] }
        | set { ch_vcfs_indexed }

      ch_vcfs.stats
        | map { meta -> [meta, meta.vcf, meta.vcf_index] }
        | stats
        | map { meta, vcfStats -> [*:meta, vcf_stats: vcfStats] }
        | set { ch_vcfs_statsed }

      ch_vcfs.ready.mix(ch_vcfs_converted, ch_vcfs_indexed, ch_vcfs_statsed)
        | flatMap { meta -> meta.metaList.collect { metaSample -> [*:meta, *:metaSample].findAll {it.key != 'metaList'} } }
        | set { ch_vcfs_preprocessed }

      // group vcfs per project
      ch_vcfs_preprocessed
        | map { meta ->
            def key = [meta.sample.project_id, meta.sample.assembly, meta.chunk]
            def size = meta.sampleSheet.count{ it.project_id == meta.sample.project_id }
            [groupKey(key, size), meta]
          }
        | groupTuple
        | map { key, group -> [project_id: key[0], assembly: key[1], chunk: key[2], sampleSheet: group.sort { it.sample.index } ] }
        | branch { meta ->
            merge_gvcfs: isGVcf(meta.sampleSheet.first().vcf)
            merge_vcfs: meta.sampleSheet.collect{ it.vcf }.unique().size() > 1
            ready: true
          }
        | set { ch_project_vcfs }

      // merge unique project vcfs
      ch_project_vcfs.merge_vcfs
        | map { meta -> [ meta, meta.sampleSheet.collect{ it.vcf }.unique(), meta.sampleSheet.collect{ it.vcf_index }.unique() ] }
        | merge_vcf
        | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats, sampleSheet: meta.sampleSheet.collect { it.sample }] }
        | set { ch_project_vcfs_merged_vcfs }

      ch_project_vcfs.merge_gvcfs
        | map { meta -> [ meta, meta.sampleSheet.collect{ it.vcf }.unique(), meta.sampleSheet.collect{ it.vcf_index }.unique() ] }
        | merge_gvcf
        | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats, sampleSheet: meta.sampleSheet.collect { it.sample }] }
        | set { ch_project_vcfs_merged_gvcfs }
      
      ch_project_vcfs.ready
        | map { meta ->
            def sample = meta.sampleSheet.first()
            [ *:meta, vcf: sample.vcf, vcf_index: sample.vcf_index, vcf_stats: sample.vcf_stats, sampleSheet: meta.sampleSheet.collect { it.sample } ]
          }
        | mix(ch_project_vcfs_merged_vcfs, ch_project_vcfs_merged_gvcfs)
        | set { ch_project_vcfs_merged }

      // scatter inputs
      ch_project_vcfs_merged
        | branch { meta ->
            scatter: meta.chunk == null
            ready: true
          }
        | set { ch_inputs }

      ch_inputs.scatter
        | flatMap { meta -> scatter(meta) }
        | branch { meta ->
            split: meta.chunk.total > 1
            ready: true
          }
        | set { ch_inputs_scattered }

      ch_inputs_scattered.split
        | map { meta -> [meta, meta.vcf, meta.vcf_index] }
        | split
        | map { meta, vcfChunk, vcfChunkIndex, vcfChunkStats -> [*:meta, vcf: vcfChunk, vcf_index: vcfChunkIndex, vcf_stats: vcfChunkStats] }
        | set { ch_inputs_splitted }
    
      ch_inputs_splitted.mix(ch_inputs_scattered.ready, ch_inputs.ready)
        | set { ch_inputs_scattered }

      // process chunks
      ch_inputs_scattered
        | map { meta -> [[*:meta, probands: getProbands(meta.sampleSheet), hpo_ids: getHpoIds(meta.sampleSheet) ], meta.vcf, meta.vcf_index, meta.vcf_stats] }
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
            | map { meta, vcf, vcfCsi, vcfStats -> [groupKey(meta.project_id, meta.chunk.total), [*:meta, vcf: vcf, vcf_index: vcfCsi, vcf_stats: vcfStats]] }
            | groupTuple
            | map { key, metaList -> 
                def filteredMetaList = metaList.findAll { meta -> nrRecords(meta.vcf_stats) > 0 }
                def meta, vcfs, vcfIndexes
                if(filteredMetaList.size() == 0) {
                  meta = metaList.first()
                  vcfs = [meta.vcf]
                  vcfIndexes = [meta.vcf_index]
                }
                else if(filteredMetaList.size() == 1) {
                  meta = filteredMetaList.first()
                  vcfs = [meta.vcf]
                  vcfIndexes = [meta.vcf_index]
                }
                else {
                  def sortedMetaList = filteredMetaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
                  meta = sortedMetaList.first()
                  vcfs = sortedMetaList.collect { it.vcf }
                  vcfIndexes = sortedMetaList.collect { it.vcf_index }
                }
                meta = [*:meta].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
                return [meta, vcfs, vcfIndexes]
              }
            | branch { meta, vcfs, vcfIndexes ->
                concat: vcfs.size() > 1
                ready: true
              }
            | set { ch_outputs }

          ch_outputs.concat
            | concat
            | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] }
            | branch { meta ->
                slice: meta.sampleSheet.any{ sample -> sample.cram != null }
                ready: true
              }
            | set { ch_concated }
     
          ch_outputs.ready
            | map { meta, vcfs, vcfIndexes -> [*:meta, vcf: vcfs.first(), vcf_index: vcfIndexes.first()] }
            | set { ch_output_singleton }

          ch_output_singleton.mix(ch_concated)
            | branch { meta ->
                slice: meta.sampleSheet.any{ sample -> sample.cram != null }
                ready: true
              }
            | set { ch_output }

        ch_output.slice
            | flatMap { meta -> meta.sampleSheet.findAll{ sample -> sample.cram != null }.collect{ sample -> [*:meta, sample: sample] } }
            | map { meta -> [meta, meta.vcf, meta.vcf_index, meta.sample.cram, meta.sample.cram_index] }
            | slice
            | map { meta, cram -> [*:meta, cram: cram] }
            | map { meta -> [groupKey(meta.project_id, meta.sampleSheet.count{ sample -> sample.cram != null }), meta] }
            | groupTuple
            | map { key, metaList -> 
                def meta = [*:metaList.first()].findAll { it.key != 'sample' && it.key != 'cram' }
                [*:meta, crams: metaList.collect { [family_id: it.sample.family_id, individual_id: it.sample.individual_id, cram: it.cram] } ]
              }
            | set { ch_sliced }

        ch_sliced.mix(ch_output.ready)
            | map { meta -> [meta, meta.vcf, meta.vcf_index, meta.crams ? meta.crams.collect { it.cram } : []] }
            | report
}

workflow {
  def sampleSheet = parseSampleSheet(params.input)
  validateParams(sampleSheet)

  // create sample channel, detect vcf and cram indexes
  Channel.from(sampleSheet)
    | map { sample -> [sample: [*:sample, vcf_index: findVcfIndex(sample.vcf), cram_index: findCramIndex(sample.cram)], sampleSheet: sampleSheet] }
    | branch { meta ->
        index_cram: meta.sample.cram != null && meta.sample.cram_index == null
        ready: true
      }
    | set { ch_sample }

  // index cram
  ch_sample.index_cram
    | map { meta -> [meta, meta.sample.cram] }
    | samtools_index
    | map { meta, cramIndex -> [*:meta, sample: [*:meta.sample, cram_index: cramIndex]] }
    | set { ch_sample_indexed_cram }

  // run vcf workflow
  ch_sample_indexed_cram.mix(ch_sample.ready)  
    | vcf
}

def validateParams(sampleSheet) {
  def assemblies = getAssemblies(sampleSheet)
  validateCommonParams(assemblies)
  
  // general
  def gvcfMergePreset = params.vcf.gvcf_merge_preset
  if (!(gvcfMergePreset ==~ /gatk|DeepVariant/))  exit 1, "parameter 'vcf.gvcf_merge_preset' value '${gvcfMergePreset}' is invalid. allowed values are [gatk, DeepVariant]"

  // annotate
  def annotSvCacheDir = params.vcf.annotate.annotsv_cache_dir
  if(!file(annotSvCacheDir).exists() )   exit 1, "parameter 'vcf.annotate.annotsv_cache_dir' value '${annotSvCacheDir}' does not exist"

  def vepCacheDir = params.vcf.annotate.vep_cache_dir
  if(!file(vepCacheDir).exists() )   exit 1, "parameter 'vcf.annotate.vep_cache_dir' value '${vepCacheDir}' does not exist"

  def vepPluginDir = params.vcf.annotate.vep_plugin_dir
  if(!file(vepPluginDir).exists() )   exit 1, "parameter 'vcf.annotate.vep_plugin_dir' value '${vepPluginDir}' does not exist"

  def vepPluginHpo = params.vcf.annotate.vep_plugin_hpo
  if(!file(vepPluginHpo).exists() )   exit 1, "parameter 'vcf.annotate.vep_plugin_hpo' value '${vepPluginHpo}' does not exist"

  def vepPluginInheritance = params.vcf.annotate.vep_plugin_inheritance
  if(!file(vepPluginInheritance).exists() )   exit 1, "parameter 'vcf.annotate.vep_plugin_inheritance' value '${vepPluginInheritance}' does not exist"

  assemblies.each { assembly ->
    def capiceModel = params.vcf.annotate[assembly].capice_model
    if(!file(capiceModel).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.capiceModel' value '${capiceModel}' does not exist"

    def vepCustomGnomad = params.vcf.annotate[assembly].vep_custom_gnomad
    if(!file(vepCustomGnomad).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_custom_gnomad' value '${vepCustomGnomad}' does not exist"

    def vepCustomClinvar = params.vcf.annotate[assembly].vep_custom_clinvar
    if(!file(vepCustomClinvar).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_custom_clinvar' value '${vepCustomClinvar}' does not exist"

    def vepCustomPhylop = params.vcf.annotate[assembly].vep_custom_phylop
    if(!file(vepCustomPhylop).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_custom_phylop' value '${vepCustomPhylop}' does not exist"
    
    def vepPluginSpliceaiIndel = params.vcf.annotate[assembly].vep_plugin_spliceai_indel
    if(!file(vepPluginSpliceaiIndel).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_plugin_spliceai_indel' value '${vepPluginSpliceaiIndel}' does not exist"

    def vepPluginSpliceaiSnv = params.vcf.annotate[assembly].vep_plugin_spliceai_snv
    if(!file(vepPluginSpliceaiSnv).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_plugin_spliceai_snv' value '${vepPluginSpliceaiSnv}' does not exist"

    def vepPluginUtrannotator = params.vcf.annotate[assembly].vep_plugin_utrannotator
    if(!file(vepPluginUtrannotator).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_plugin_utrannotator' value '${vepPluginUtrannotator}' does not exist"

    def vepPluginVkgl = params.vcf.annotate[assembly].vep_plugin_vkgl
    if(!file(vepPluginVkgl).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_plugin_vkgl' value '${vepPluginVkgl}' does not exist"
  }

  // classify
  assemblies.each { assembly ->
    def decisionTree = params.vcf.classify[assembly].decision_tree
    if(!file(decisionTree).exists() )   exit 1, "parameter 'vcf.classify.${assembly}.decision_tree' value '${decisionTree}' does not exist"

    def samplesDecisionTree = params.vcf.classify_samples[assembly].decision_tree
    if(!file(samplesDecisionTree).exists() )   exit 1, "parameter 'vcf.classify_samples.${assembly}.decision_tree' value '${samplesDecisionTree}' does not exist"
  }

  // report
  def template = params.vcf.report.template
  if(!template.isEmpty() && !file(template).exists() )   exit 1, "parameter 'vcf.report.template' value '${template}' does not exist"

  assemblies.each { assembly ->
    def genes = params.vcf.report[assembly].genes
    if(!file(genes).exists() )   exit 1, "parameter 'vcf.report.${assembly}.genes' value '${genes}' does not exist"
  }
}

def parseSampleSheet(csvFile) {
  def cols = [
    vcf: [
      type: "file",
      required: true,
      regex: getVcfRegex()
    ],
    cram: [
      type: "file",
      regex: /.+(?:\.bam|\.cram)/
    ],
  ]
  return parseCommonSampleSheet(csvFile, cols)
}