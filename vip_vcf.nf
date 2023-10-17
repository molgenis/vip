nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { getCramRegex; getVcfRegex; getRnaRegex } from './modules/utils'
include { validate } from './modules/vcf/validate.nf'
include { split } from './modules/vcf/split'
include { normalize } from './modules/vcf/normalize'
include { annotate; annotate_publish } from './modules/vcf/annotate'
include { classify; classify_publish } from './modules/vcf/classify'
include { filter } from './modules/vcf/filter'
include { inheritance } from './modules/vcf/inheritance'
include { classify_samples; classify_samples_publish } from './modules/vcf/classify_samples'
include { filter_samples } from './modules/vcf/filter_samples'
include { concat } from './modules/vcf/concat'
include { slice } from './modules/vcf/slice'
include { report } from './modules/vcf/report'
include { nrRecords; getProbands; getHpoIds; scatter; preGroupTupleConcat; postGroupTupleConcat; createCountTemplate } from './modules/vcf/utils'
include { featureCounts; cut; createMatrix } from './modules/vcf/featureCounts'
include { outrider; rnaResults } from './modules/vcf/outrider'

/**
 * input: [project, vcf, ...]
 */
workflow vcf {
    take: meta
    main:

      // Take all samples containing RNA-seq data
      meta
        | view
        | branch { meta ->
          rna: meta.project.samples.any{ sample -> sample.rna != null }
          ready: true
          }
        | set {ch_drop}

      /**
       Convert sample RNA bam files to count matrices using featureCounts and merge them into
       a combined count matrix to be used in outrider. 
       **/
      ch_drop.rna
        | map { meta -> [meta, meta.project.samples.rna[0], meta.project.samples.individual_id[0]] }
        | featureCounts
        | cut
        | combine(Channel.of(createCountTemplate()))
        | createMatrix
        | set {ch_countMatrix}

      // /**
      // Grab the final created count matrix and run it through outrider with external count data
      // **/
      ch_countMatrix
        | last
        | outrider
        | set { outriderResults }

      /**
      Split the outrider result table in seperate tables per sample and add them to the meta data variable
      **/

      ch_drop.rna.combine(outriderResults)
        | map { meta, results -> [meta, results, meta.project.samples.individual_id[0]]}
        | rnaResults
        | map { meta, result -> [*:meta, rna: [matrix: result]]}
        | set { ch_rna_ready }

      ch_drop.ready.mix(ch_rna_ready)
        | flatMap { meta -> scatter(meta) }
        | branch { meta ->
            split: meta.chunk.total > 1
            ready: true
          }
        | set { ch_inputs_scattered }

      ch_inputs_scattered.split
        | map { meta -> [meta, meta.vcf.data, meta.vcf.index] }
        | split
        | map { meta, vcfChunk, vcfChunkIndex, vcfChunkStats -> [*:meta, vcf: [data: vcfChunk, index: vcfChunkIndex, stats: vcfChunkStats]] }
        | set { ch_inputs_scattered_split }

      // process chunks
      Channel.empty().mix(ch_inputs_scattered.ready, ch_inputs_scattered_split)
        | map { meta -> [[*:meta, probands: getProbands(meta.project.samples), hpo_ids: getHpoIds(meta.project.samples) ], meta.vcf.data, meta.vcf.index, meta.vcf.stats] }
        | branch { meta, vcf, vcfIndex, vcfStats ->
            process: nrRecords(vcfStats) > 0
            empty: true
          }
        | set { ch_inputs }

      ch_inputs.process
        | branch {
            take: params.vcf.start.isEmpty() || params.vcf.start ==~ /normalize/
            skip: true
          }
        | set { ch_normalize }

      // normalize
      ch_normalize.take
        | normalize
        | set { ch_normalized }

      // annotate
      ch_normalized.mix(ch_normalize.skip)
        | branch {
            take: params.vcf.start.isEmpty() || params.vcf.start ==~ /normalize|annotate/
            skip: true
          }
        | set { ch_annotate }

      ch_annotate.take
          | annotate
          | multiMap { it -> done: publish: it }
          | set { ch_annotated }

      ch_annotated.publish.mix(ch_inputs.empty)
          | map { meta, vcf, vcfCsi, vcfStats -> preGroupTupleConcat(meta, vcf, vcfCsi, vcfStats) }
          | groupTuple
          | map { key, metaList -> postGroupTupleConcat(key, metaList) }
          | annotate_publish

      // classify
      ch_annotated.done.mix(ch_annotate.skip)
        | branch {
            take: params.vcf.start.isEmpty() || params.vcf.start ==~ /normalize|annotate|classify/
            skip: true
          }
        | set { ch_classify }

      ch_classify.take
        | classify
        | multiMap { it -> done: publish: it }
        | set { ch_classified }

      ch_classified.publish.mix(ch_inputs.empty)
        | map { meta, vcf, vcfCsi, vcfStats -> preGroupTupleConcat(meta, vcf, vcfCsi, vcfStats) }
        | groupTuple
        | map { key, metaList -> postGroupTupleConcat(key, metaList) }
        | classify_publish

        // filter
        ch_classified.done.mix(ch_classify.skip)
          | branch {
              take: params.vcf.start.isEmpty() || params.vcf.start ==~ /normalize|annotate|classify|filter/
              skip: true
            }
          | set { ch_filter }

        ch_filter.take
          | filter
          | branch { meta, vcf, vcfIndex, vcfStats ->
              process: nrRecords(vcfStats) > 0
              empty: true
            }
          | set { ch_filtered }

        // inheritance
        ch_filtered.process.mix(ch_filter.skip)
          | branch {
              take: params.vcf.start.isEmpty() || params.vcf.start ==~ /normalize|annotate|classify|filter|inheritance/
              skip: true
            }
          | set { ch_inheritance }

        ch_inheritance.take
            | inheritance
            | set { ch_inheritanced }

        // classify samples
        ch_inheritanced.mix(ch_inheritance.skip)
          | branch {
              take: params.vcf.start.isEmpty() || params.vcf.start ==~ /normalize|annotate|classify|filter|inheritance|classify_samples/
              skip: true
            }
          | set { ch_classify_samples }

        ch_classify_samples.take
          | classify_samples
          | multiMap { it -> done: publish: it }
          | set { ch_classified_samples }

        ch_classified_samples.publish.mix(ch_inputs.empty, ch_filtered.empty)
          | map { meta, vcf, vcfCsi, vcfStats -> preGroupTupleConcat(meta, vcf, vcfCsi, vcfStats) }
          | groupTuple
          | map { key, metaList -> postGroupTupleConcat(key, metaList) }
          | classify_samples_publish

        // filter samples
        ch_classified_samples.done.mix(ch_classify_samples.skip)
          | branch {
              take: params.vcf.start.isEmpty() || params.vcf.start ==~ /normalize|annotate|classify|filter|inheritance|classify_samples|filter_samples/
              skip: true
            }
          | set { ch_filter_samples }

        ch_filter_samples.take
          | filter_samples
          | branch { meta, vcf, vcfIndex, vcfStats ->
              process: nrRecords(vcfStats) > 0
              empty: true
            }
          | set { ch_filtered_samples }

        // concat
        ch_filtered_samples.process.mix(ch_filter_samples.skip, ch_inputs.empty, ch_filtered.empty, ch_filtered_samples.empty)
          | map { meta, vcf, vcfCsi, vcfStats -> preGroupTupleConcat(meta, vcf, vcfCsi, vcfStats) }
          | groupTuple
          | map { key, metaList -> postGroupTupleConcat(key, metaList) }
          | branch { meta, vcfs, vcfIndexes ->
              concat: vcfs.size() > 1
              ready: true
            }
          | set { ch_outputs }

        ch_outputs.concat
            | concat
            | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats] }
            | branch { meta ->
                slice: meta.samples.any{ sample -> sample.cram != null }
                ready: true
              }
            | set { ch_concated }
     
          ch_outputs.ready
            | map { meta, vcfs, vcfIndexes -> [*:meta, vcf: vcfs.first(), vcf_index: vcfIndexes.first()] }
            | set { ch_output_singleton }

          ch_output_singleton.mix(ch_concated)
            | branch { meta ->
                slice: meta.samples.any{ sample -> sample.cram != null }
                ready: true
              }
            | set { ch_output }

        ch_output.slice
            | flatMap { meta -> meta.samples.findAll{ sample -> sample.cram != null }.collect{ sample -> [*:meta, sample: sample] } }
            | map { meta -> [meta, meta.vcf, meta.vcf_index, meta.sample.cram] }
            | slice
            | map { meta, cram -> [*:meta, cram: cram] }
            | map { meta -> [groupKey(meta.project.id, meta.project.samples.count{ sample -> sample.cram != null }), meta] }
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
  def projects = parseSampleSheet(params.input)
  def assemblies = getAssemblies(projects)
  validateVcfParams(assemblies)

  // validate project vcfs
  Channel.from(projects)
    | map { project -> [[project: project], project.vcf] }
    | validate
    | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: [data: vcf, index: vcfIndex, stats: vcfStats]] }
    | set { ch_vcf_validated }

  // run vcf workflow
  ch_vcf_validated
    | vcf
}

def validateVcfParams(assemblies) {
  validateCommonParams(assemblies)
  
  // general
  def start = params.vcf.start
  if (!start.isEmpty() && !(start ==~ /normalize|annotate|classify|filter|inheritance|classify_samples|filter_samples/))  exit 1, "parameter 'vcf.start' value '${start}' is invalid. allowed values are [normalize, annotate, classify, filter, inheritance, classify_samples, filter_samples]"

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
  def includeCrams = params.vcf.report.include_crams
  if (!(includeCrams ==~ /true|false/))  exit 1, "parameter 'params.vcf.report.include_crams' value '${includeCrams}' is invalid. allowed values are [true, false]"
  
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
      regex: getVcfRegex(),
      scope: "project"
    ],
    cram: [
      type: "file",
      regex: getCramRegex()
    ],
    rna: [
      type: "file",
      regex: getRnaRegex()
    ],
  ]
  return parseCommonSampleSheet(csvFile, cols)
}