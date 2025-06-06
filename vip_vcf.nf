nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { getCramRegex; getVcfRegex; validateGroup } from './modules/utils'
include { validate as validate_vcf } from './modules/vcf/validate'
include { liftover as liftover_vcf } from './modules/vcf/liftover'
include { validate as validate_cram; validate as validate_cram_rna } from './modules/cram/validate'
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
include { slice_rna } from './modules/vcf/slice_rna'
include { report } from './modules/vcf/report'
include { nrRecords; getProbands; getHpoIds; scatter; preGroupTupleConcat; postGroupTupleConcat; getProbandHpoIds; areProbandHpoIdsIndentical } from './modules/vcf/utils'
include { gado } from './modules/vcf/gado'
include { bed_filter } from './modules/vcf/bed_filter'

/**
 * input: [project, vcf, chunk (optional), ...]
 */
workflow vcf {
    take: meta
    main:
      meta
        | branch { meta ->
              run: !getProbandHpoIds(meta.project.samples).join(",").isEmpty() && areProbandHpoIdsIndentical(meta.project.samples)
              skip: true
        }
        | set { ch_gado }

        ch_gado.run
        | gado
        | map { meta, gado_scores -> [*:meta, gado: gado_scores] }
        | set { ch_gado_done }

        ch_gado_done.mix(ch_gado.skip)
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

      Channel.empty().mix(ch_inputs_scattered.split, ch_inputs.ready)
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
          | groupTuple(remainder: true)
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
        | groupTuple(remainder: true)
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
          | groupTuple(remainder: true)
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
          | groupTuple(remainder: true)
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
                slice: meta.project.samples.any{ sample -> sample.cram != null }
                ready: true
              }
            | set { ch_concated }
     
          ch_outputs.ready
            | map { meta, vcfs, vcfIndexes -> [*:meta, vcf: vcfs.first(), vcf_index: vcfIndexes.first()] }
            | set { ch_output_singleton }

          ch_output_singleton.mix(ch_concated)
            | branch { meta ->
                slice: meta.project.samples.any{ sample -> sample.cram != null }
                ready: true
              }
            | set { ch_output }

        ch_output.slice
            | flatMap { meta -> meta.project.samples.findAll{ sample -> sample.cram != null }.collect{ sample -> [*:meta, sample: sample] } }
            | map { meta -> [meta, meta.vcf, meta.vcf_index, meta.sample.cram.data] }
            | slice
            | map { meta, cram -> [*:meta, cram: cram] }
            | map { meta -> [groupKey(meta.project.id, meta.project.samples.count{ sample -> sample.cram != null }), meta] }
            | groupTuple(remainder: true)
            | map { key, metaList -> 
                def meta = [*:metaList.first()].findAll { it.key != 'sample' && it.key != 'cram' }
                [*:meta, crams: metaList.collect { [family_id: it.sample.family_id, individual_id: it.sample.individual_id, cram: it.cram] } ]
              }
            | set { ch_sliced }

        ch_sliced.mix(ch_output.ready)
            | branch { meta ->
                slice: meta.project.samples.any{ sample -> sample.cram_rna != null }
                ready: true
              }
            | set { ch_slice_rna }

        ch_slice_rna.slice
            | flatMap { meta -> meta.project.samples.findAll{ sample -> sample.cram_rna != null }.collect{ sample -> [*:meta, sample: sample] } }
            | map { meta -> [meta, meta.vcf, meta.vcf_index, meta.sample.cram_rna.data] }
            | slice_rna
            | map { meta, cram_rna -> [*:meta, cram_rna: cram_rna] }
            | map { meta -> [groupKey(meta.project.id, meta.project.samples.count{ sample -> sample.cram_rna != null }), meta] }
            | groupTuple(remainder: true)
            | map { key, metaList -> 
                def meta = [*:metaList.first()].findAll { it.key != 'sample' && it.key != 'cram_rna' }
                [*:meta, crams_rna: metaList.collect { [family_id: it.sample.family_id, individual_id: it.sample.individual_id, cram_rna: it.cram_rna, cram: it.sample.cram] } ]
              }
            | set { ch_sliced_rna }

        ch_sliced_rna.mix(ch_slice_rna.ready)
            | map { meta -> [meta, meta.vcf, meta.vcf_index, meta.crams ? meta.crams.collect { it.cram } : [], meta.crams_rna ? meta.crams_rna.collect { it.cram_rna } : []] }
            | report
}

workflow {
  def projects = parseSampleSheet(params)
  def assemblies = getAssemblies(projects)
  validateVcfParams(assemblies)

  // preprocess vcfs and crams in parallel
  Channel.from(projects)
    | map { project -> [project: project] }
    | multiMap { it -> vcf: cram: it }
    | set { ch_project }

  // validate and liftover vcf per project
	ch_project.vcf
	  | map { meta -> [meta, meta.project.vcf] }
	  | validate_vcf
    | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
	  | branch { meta, vcf ->
	      bed_filter: meta.project.regions != null
	      ready: true
	    }
    | set { ch_project_vcf_validated }

  //filter
  ch_project_vcf_validated.bed_filter
    | map { meta, vcf -> [meta, meta.project.regions, vcf.data, vcf.index, false] }
    | bed_filter
    | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
    | set { ch_project_vcf_filtered }

  Channel.empty().mix(ch_project_vcf_filtered, ch_project_vcf_validated.ready)
  	| branch { meta, vcf ->
	    liftover: meta.project.assembly != params.assembly
	    ready: true
	  }
    | set { ch_project_liftover }

  // liftover vcf
  ch_project_liftover.liftover
    | map { meta, vcf -> [meta, vcf.data] }
    | liftover_vcf
    | map { meta, vcf, vcfIndex, vcfStats, vcfRejected, vcfIndexRejected, vcfStatsRejected -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
    | set { ch_project_vcf_liftovered }

  // merge vcf channels
  Channel.empty().mix(ch_project_vcf_liftovered, ch_project_liftover.ready)
    | map { meta, vcf -> [meta, [vcf: vcf]] }
    | set { ch_project_vcf_processed }

  // validate cram per sample
	ch_project.cram
	  | flatMap { meta -> meta.project.samples.collect { sample -> [*:meta, sample: sample] } }
	  | branch { meta ->
				process: meta.sample.cram != null
				ready:   true
                 return [meta, null]
			}
	  | set { ch_sample_cram }

  // validate cram
	ch_sample_cram.process
	  | map { meta -> [meta, meta.project.assembly, meta.sample.cram] }
	  | validate_cram
	  | map { meta, cram, cramIndex, cramStats -> [meta, [data: cram, index: cramIndex, stats: cramStats]] }
    | set { ch_sample_cram_validated }

  // merge cram channels per project
  Channel.empty().mix(ch_sample_cram_validated, ch_sample_cram.ready)
	  | branch { meta, cram ->
				process: meta.sample.cram_rna != null
				ready:   true
                 return [meta, cram, null]
			}
    | set { ch_sample_cram_rna }

  // validate rna cram
	ch_sample_cram_rna.process
	  | map { meta, cram -> [[*:meta, cram:cram], meta.project.assembly, meta.sample.cram_rna] }
	  | validate_cram_rna
	  | map { meta, cramRna, cramRnaIndex, cramRnaStats -> [meta, meta.cram, [data: cramRna, index: cramRnaIndex, stats: cramRnaStats]] }
    | map { meta, cram, cram_rna -> 
        meta.remove('cram')
        [meta, cram, cram_rna]
      }
    | set { ch_sample_cram_rna_validated }

  Channel.empty().mix(ch_sample_cram_rna_validated, ch_sample_cram_rna.ready)
    | map { meta, cram, cram_rna -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), [sample: meta.sample, cram: cram, cram_rna: cram_rna]] }
    | groupTuple(remainder: true, sort: { left, right -> left.sample.index <=> right.sample.index })
    | map { key, group -> validateGroup(key, group) }
    | map { meta, containers -> [meta, [samples: containers.collect { [*:it.sample, cram: it.cram, cram_rna: it.cram_rna] }]] }
    | set { ch_project_cram_processed }

  // merge vcf and cram channels and update project
	Channel.empty().mix(ch_project_vcf_processed, ch_project_cram_processed)
    | map { meta, container -> [groupKey(meta, 2), container] }
    | groupTuple(remainder: true)
    | map { key, group -> validateGroup(key, group) }
    | map { meta, containers ->
        def vcf = containers.find { it.vcf != null }.vcf
        def samples = containers.find { it.samples != null }.samples
        [*:meta, vcf: vcf, project: [*:meta.project, assembly: params.assembly, samples: samples]]
      }
    | set { ch_project_processed }

  // run vcf workflow
  ch_project_processed
    | vcf
}

def validateVcfParams(inputAssemblies) {
  validateCommonParams(inputAssemblies)
  def outputAssemblies = [params.assembly]
  
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

  outputAssemblies.each { assembly ->
    def capiceModel = params.vcf.annotate[assembly].capice_model
    if(!file(capiceModel).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.capiceModel' value '${capiceModel}' does not exist"
    
    def vepCustomPhylop = params.vcf.annotate[assembly].vep_custom_phylop
    if(!file(vepCustomPhylop).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_custom_phylop' value '${vepCustomPhylop}' does not exist"
    
    def vepPluginClinvar = params.vcf.annotate[assembly].vep_plugin_clinvar
    if(!file(vepPluginClinvar).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_plugin_clinvar' value '${vepPluginClinvar}' does not exist"

    def vepPluginGnomad = params.vcf.annotate[assembly].vep_plugin_gnomad
    if(!file(vepPluginGnomad).exists() )   exit 1, "parameter 'vcf.annotate.${assembly}.vep_plugin_gnomad' value '${vepPluginGnomad}' does not exist"

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
  outputAssemblies.each { assembly ->
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

  outputAssemblies.each { assembly ->
    def genes = params.vcf.report[assembly].genes
    if(!file(genes).exists() )   exit 1, "parameter 'vcf.report.${assembly}.genes' value '${genes}' does not exist"
  }
}

def parseSampleSheet(params) {
  def cols = [
  	assembly: [
			type: "string",
			default: { 'GRCh38' },
			enum: ['GRCh37', 'GRCh38', 'T2T'],
      scope: "project"
		],
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
    cram_rna: [
      type: "file",
      regex: getCramRegex()
    ]
  ]

  def projects = parseCommonSampleSheet(params.input, params.hpo_phenotypic_abnormality, cols)
  validate(projects)
  return projects
}

def validate(projects) {
  projects.each { project ->
    project.samples.each { sample ->
      if ((project.assembly != params.assembly) && (sample.cram != null)) {
        throw new IllegalArgumentException("line ${sample.index}: 'cram' column must be empty because input assembly '${sample.assembly}' differs from output assembly '${params.assembly}' (liftover not possible).")
      }
    }
  }
}