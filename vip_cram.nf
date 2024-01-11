nextflow.enable.dsl=2

include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { getCramRegex; validateGroup } from './modules/utils'
include { validate as validate_cram } from './modules/cram/validate'
include { vcf; validateVcfParams } from './vip_vcf'
include { snv; validateCallSnvParams } from './subworkflows/call_snv'
include { str; validateCallStrParams } from './subworkflows/call_str'
include { sv; validateCallSvParams } from './subworkflows/call_sv'
include { concat_vcf } from './modules/cram/concat_vcf'

/**
 * input:  [project, sample, ...]
 * output: [project, vcf,    ...]
 */
workflow cram {
  take: meta
  main:
    def nrActivateVariantCallerTypes = 0
    if(params.cram.call_snv) ++nrActivateVariantCallerTypes;
    if(params.cram.call_str) ++nrActivateVariantCallerTypes;
    if(params.cram.call_sv)  ++nrActivateVariantCallerTypes;

    // output pre-preprocessed crams to snv, str and sv channels
    meta
      | multiMap { it -> snv: str: sv: it }
      | set { ch_cram_multi }

    // snv
    ch_cram_multi.snv
      | filter { params.cram.call_snv == true }
      | snv
      | set { ch_cram_snv }

    // str
    ch_cram_multi.str
      | filter { params.cram.call_str == true }
      | str
      | set { ch_cram_str }

    // sv
    ch_cram_multi.sv
      | filter { params.cram.call_sv == true }
      | sv
      | set { ch_cram_sv }

    // merge outputs of snv, str and sv workflows
    Channel.empty().mix(ch_cram_snv, ch_cram_str, ch_cram_sv)
      | map { meta, vcf -> [groupKey(meta, nrActivateVariantCallerTypes), vcf] }
      | groupTuple(remainder: true, sort: { left, right -> left.index <=> right.index })
      | map { key, group -> validateGroup(key, group) }
      | branch { meta, vcfs ->
          multiple: vcfs.count { it != null } > 1
                    return [meta, vcfs.findAll { it != null } ]
          single:   vcfs.count { it != null } == 1
                    return [meta, vcfs.find { it != null } ]
          zero:     true
                    return [meta, null]
        }
      | set { ch_cram_called }

    // multiple variant callers: perform merge
    ch_cram_called.multiple
      | map { meta, vcfs -> [meta, vcfs.collect { it.data }, vcfs.collect { it.index }] }
      | concat_vcf
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_cram_called_multiple }

    // continue with vcf workflow
    Channel.empty().mix(ch_cram_called_multiple, ch_cram_called.single ) // FIXME deal with projects ending up in ch_cram_called.zero
      | map { meta, vcf -> [*:meta, vcf: vcf] }
      | vcf
}

workflow {
  def projects = parseSampleSheet(params.input)
  def assemblies = getAssemblies(projects)
  validateCramParams(assemblies)

  // run workflow for each sample in each project
  Channel.from(projects)
    | flatMap { project -> project.samples.collect { sample -> [project: project, sample: sample] } }
    | set { ch_sample }

  // validate cram
  ch_sample
    | map { meta -> [meta, meta.project.assembly, meta.sample.cram] }
    | validate_cram
    | map { meta, cram, cramIndex, cramStats -> [*:meta, sample: [*:meta.sample, cram: [data: cram, index: cramIndex, stats: cramStats]]] }
    | set { ch_sample_validated }

  // update project samples
  ch_sample_validated
    | map { meta -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), meta.sample] }
    | groupTuple(remainder: true, sort: { left, right -> left.index <=> right.index })
    | map { key, group -> validateGroup(key, group) }
    | map { meta, samples -> [*:meta, project: [*:meta.project, samples: samples]] }
    | set { ch_project_validated }

  // decide whether realignment is required
  ch_project_validated
    | flatMap { meta -> meta.project.samples.collect { sample -> [*:meta, sample: sample] } }
    | cram
}

def validateCramParams(inputAssemblies) {
  validateVcfParams(inputAssemblies)
  def outputAssemblies = [params.assembly]

  def callSnv = params.cram.call_snv
  if (!(callSnv ==~ /true|false/))  exit 1, "parameter 'cram.call_snv' value '${callSnv}' is invalid. allowed values are [true, false]"

  def callStr = params.cram.call_str
  if (!(callStr ==~ /true|false/))  exit 1, "parameter 'cram.call_str' value '${callStr}' is invalid. allowed values are [true, false]"

  def callSv = params.cram.call_sv
  if (!(callSv ==~ /true|false/))  exit 1, "parameter 'cram.call_sv' value '${callSv}' is invalid. allowed values are [true, false]"
  
  if (callSnv == false && callStr == false && callSv == false) exit 1, "parameters 'cram.call_snv', 'cram.call_str' and 'cram.call_sv' are false. at least one must be true"

  if(callSnv) validateCallSnvParams(outputAssemblies)
  if(callStr) validateCallStrParams(outputAssemblies)
  if(callSv)  validateCallSvParams(outputAssemblies)
}

def parseSampleSheet(csvFile) {
  def cols = [
    cram: [
      type: "file",
      required: true,
      regex: getCramRegex()
    ],
    sequencing_platform: [
      type: "string",
      required: true,
      default: { 'illumina' },
      enum: ['illumina', 'nanopore', 'pacbio_hifi'],
      scope: "project"
    ]
  ]

  def projects = parseCommonSampleSheet(csvFile, cols)
  return projects.collect { project -> [*:project, assembly: params.assembly] }
}
