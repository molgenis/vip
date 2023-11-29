nextflow.enable.dsl=2

include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { getCramRegex; getGenomeVcfRegex } from './modules/utils'
include { validate as validate_gvcf } from './modules/gvcf/validate'
include { liftover as liftover_gvcf } from './modules/gvcf/liftover'
include { validate as validate_cram } from './modules/cram/validate'
include { scatter; validateGroup } from './modules/utils'
include { merge } from './modules/gvcf/merge'
include { vcf; validateVcfParams } from './vip_vcf'

/**
 * input:  [project, sample, ...]
 */
workflow gvcf {
  take: meta
  main:
    meta
      | flatMap { meta -> scatter(meta) }
      | set { ch_inputs_scattered }

    // joint variant calling per project, per chunk
    ch_inputs_scattered
      | map { meta -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), meta.sample] }
      | groupTuple(remainder: true, sort: { left, right -> left.index <=> right.index })
      | map { key, group -> validateGroup(key, group) }
      | map { meta, samples -> [meta, samples.collect { it.gvcf.data }, samples.collect { it.gvcf.index } ]}
      | merge
      | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_vcf_per_chunk_called }

    ch_vcf_per_chunk_called  
      | vcf
}

workflow {
  def projects = parseSampleSheet(params.input)
  def assemblies = getAssemblies(projects)
  validateGenomeVcfParams(assemblies)

  // run workflow for each sample in each project
  Channel.from(projects)
    | flatMap { project -> project.samples.collect { sample -> [project: project, sample: sample] } }
    | set { ch_sample }

  // validate gvcf and decide whether liftover if required
  ch_sample
    | map { meta -> [meta, meta.sample.gvcf] }
    | validate_gvcf
    | map { meta, gVcf, gVcfIndex, gVcfStats -> [meta, [data: gVcf, index: gVcfIndex, stats: gVcfStats]] }
    | branch { meta, gVcf ->
	      liftover: meta.sample.assembly != params.assembly
	      ready: true
	    }
    | set { ch_sample_validated }

  // liftover gvcf
  ch_sample_validated.liftover
    | map { meta, gVcf -> [meta, gVcf.data] }
    | liftover_gvcf
    | map { meta, gVcf, gVcfIndex, gVcfStats, gVcfRejected, gVcfRejectedIndex, gVcfRejectedStats -> [meta, [data: gVcf, index: gVcfIndex, stats: gVcfStats]] }
    | set { ch_sample_liftover }

  // merge vcf channels
  Channel.empty().mix(ch_sample_liftover, ch_sample_validated.ready)
    | map { meta, gVcf -> [*:meta, sample: [*:meta.sample, gvcf: gVcf]] }
    | set { ch_sample_processed }

  // update project assembly and samples
  ch_sample_processed
    | map { meta -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), meta.sample] }
    | groupTuple(remainder: true, sort: { left, right -> left.index <=> right.index })
    | map { key, group -> validateGroup(key, group) }
    | map { meta, samples -> [*:meta, project: [*:meta.project, assembly: params.assembly, samples: samples]] }
    | set { ch_project_processed }

  // map to updated samples
  ch_project_processed
    | flatMap { meta -> meta.project.samples.collect { sample -> [*:meta, sample: sample] } }
    | gvcf
}

def validateGenomeVcfParams(assemblies) {
  validateVcfParams(assemblies)

  // general
  def mergePreset = params.gvcf.merge_preset
  if (!(mergePreset ==~ /gatk|gatk_unfiltered|DeepVariant|DeepVariant_unfiltered/))  exit 1, "parameter 'gvcf.merge_preset' value '${mergePreset}' is invalid. allowed values are [gatk, gatk_unfiltered, DeepVariant, DeepVariant_unfiltered]"
}

def parseSampleSheet(csvFile) {
  def cols = [
		assembly: [
			type: "string",
			default: { 'GRCh38' },
			enum: ['GRCh37', 'GRCh38', 'T2T']
		],
    gvcf: [
      type: "file",
      required: true,
      regex: getGenomeVcfRegex()
    ],
    cram: [
      type: "file",
      regex: getCramRegex()
    ]
  ]
  
  def projects = parseCommonSampleSheet(csvFile, cols)
  validate(projects)
  return projects
}

def validate(projects) {
  projects.each { project ->
    project.samples.each { sample ->
      if ((sample.assembly != params.assembly) && (sample.cram != null)) {
        throw new IllegalArgumentException("line ${sample.index}: 'cram' column must be empty because input assembly '${sample.assembly}' differs from output assembly '${params.assembly}' (liftover not possible).")
      }
    }
  }
}