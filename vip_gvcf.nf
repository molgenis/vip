nextflow.enable.dsl=2

include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { getCramRegex; getGenomeVcfRegex } from './modules/utils'
include { validate } from './modules/gvcf/validate'
include { merge } from './modules/gvcf/merge'
include { vcf; validateVcfParams } from './vip_vcf'

/**
 * input:  [project, sample, ...]
 */
workflow gvcf {
    take: meta
    main:
      meta
        | map { meta -> [groupKey(meta.project, meta.project.samples.size), meta.sample] }
        | groupTuple
        | map { key, group -> [key.getGroupTarget(), group.sort { it.index } ] }
        | map { project, samples -> [[project: project], samples.collect { it.gvcf.data }, samples.collect { it.gvcf.index } ]}
        | merge
        | map { meta, vcf, vcfIndex, vcfStats -> [*:meta, vcf: [data: vcf, index: vcfIndex, stats: vcfStats]] }
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

  // validate sample gvcf
  ch_sample
    | map { meta -> [meta, meta.sample.gvcf] }
    | validate
    | map { meta, gVcf, gVcfIndex, gVcfStats -> [*:meta, sample: [*:meta.sample, gvcf: [data: gVcf, index: gVcfIndex, stats: gVcfStats]]] }
    | set { ch_sample_validated }

  ch_sample_validated
    | gvcf
}

def validateGenomeVcfParams(assemblies) {
  validateVcfParams(assemblies)

  // general
  def mergePreset = params.gvcf.merge_preset
  if (!(mergePreset ==~ /gatk|gatk_unfiltered|DeepVariant/))  exit 1, "parameter 'gvcf.merge_preset' value '${mergePreset}' is invalid. allowed values are [gatk, gatk_unfiltered, DeepVariant]"
}

def parseSampleSheet(csvFile) {
  def cols = [
    gvcf: [
      type: "file",
      required: true,
      regex: getGenomeVcfRegex()
    ],
    cram: [
      type: "file",
      regex: getCramRegex()
    ],
  ]
  return parseCommonSampleSheet(csvFile, cols)
}