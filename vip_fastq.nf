nextflow.enable.dsl=2

include { parseCommonSampleSheet } from './modules/sample_sheet'
include { minimap2_align; minimap2_align_paired_end } from './modules/fastq/minimap2'
include { cram; validateCramParams } from './vip_cram'
include { splitPerFastqSingle; splitPerFastqPaired } from './modules/fastq/utils'
include { merge_cram } from './modules/fastq/merge'

/**
 * input:  [project, sample [...      ], ...]
 * output: [project, sample [cram, ...], ...]
 */
workflow fastq {
  take: meta
  main:
    meta
      | branch { meta ->
          paired_end: !meta.sample.fastq_r1.isEmpty() && !meta.sample.fastq_r2.isEmpty()
          single: true
        }
      | set { ch_input }
    
    // paired-end fastq
    ch_input.paired_end
      | branch { meta ->
          process: meta.sample.fastq_r1.size() > 1 || meta.sample.fastq_r2.size() > 1
          ready: true
        }
      | set { ch_input_paired_end }
    
    ch_input_paired_end.process
      | flatMap { meta -> splitPerFastqPaired(meta) }
      | set { ch_input_paired_end_by_pair }

    ch_input_paired_end.ready
      | map { meta -> [*:meta, sample: [*:meta.sample, fastq: [data_r1: meta.sample.fastq_r1, data_r2: meta.sample.fastq_r2, total: 1, index: 0]]]}
      | set{ch_input_paired_end_ready}

    Channel.empty().mix(ch_input_paired_end_by_pair, ch_input_paired_end_ready)
      | map { meta -> [meta, meta.sample.fastq.data_r1, meta.sample.fastq.data_r2] }
      | minimap2_align_paired_end
      | map {meta, cram, cramCrai, cramStats -> [groupKey(meta.sample.individual_id, meta.sample.fastq.total), meta, cram]}
      | groupTuple
      | map { key, meta, cram -> [meta[0], cram]}
      | set { ch_input_paired_end_aligned }
    
    // single fastq
    ch_input.single
      | branch { meta ->
          flatten: meta.sample.fastq.size() > 1
          ready: true
        }
      | set { ch_input_single }
    
    ch_input_single.flatten
      | flatMap { meta -> splitPerFastqSingle(meta) }
      | set { ch_input_single_flattened }

    ch_input_single.ready
      | map { meta -> [*:meta, sample: [*:meta.sample, fastq: [data: meta.sample.fastq, total: 1, index: 0]]] }
      | set{ch_input_single_ready}

    ch_input_single_flattened.mix(ch_input_single_ready)
      | map { meta -> [meta, meta.sample.fastq.data] }
      | minimap2_align
      | map {meta, cram, cramCrai, cramStats -> [groupKey(meta.sample.individual_id, meta.sample.fastq.total), meta, cram]}
      | groupTuple
      | map { key, meta, cram -> [meta[0], cram]}
      | set { ch_input_single_aligned }

    ch_input_paired_end_aligned.mix(ch_input_single_aligned)
      | merge_cram
      | map { meta, cram, cramIndex, cramStats -> [*:meta, project: [*:meta.project, assembly: params.assembly], sample: [*:meta.sample, cram: [data: cram, index: cramIndex, stats: cramStats]]] }
      | cram
}

workflow {
  def projects = parseSampleSheet(params.input)
  validateFastqParams([params.assembly])

  // run fastq workflow for each sample in each project
  Channel.from(projects)
    | flatMap { project -> project.samples.collect { sample -> [project: project, sample: sample] } }
    | fastq
}

def validateFastqParams(assemblies) {
  validateCramParams(assemblies)
  
  def softClipping = params.minimap2.soft_clipping
  if (!(softClipping ==~ /true|false/))  exit 1, "parameter 'minimap2.soft_clipping' value '${softClipping}' is invalid. allowed values are [true, false]"

  assemblies.each { assembly ->
    def fastaMmi = params[assembly].reference.fastaMmi
    if(!fastaMmi.isEmpty() && !file(fastaMmi).exists() )   exit 1, "parameter '${assembly}.reference.fastaMmi' value '${fastaMmi}' does not exist"
  }  
}

def parseSampleSheet(csvFile) {
  def fastqRegex = /.+\.(fastq|fq)(\.gz)?/
  
  def cols = [
    fastq: [
      type: "file",
      required: true,
      list: true,
      regex: fastqRegex
    ],
    fastq_r1: [
      type: "file",
      required: true,
      list: true,
      regex: fastqRegex
    ],
    fastq_r2: [
      type: "file",
      required: true,
      list: true,
      regex: fastqRegex
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
  validate(projects)
  return projects
}

def validate(projects) {
  projects.each { project ->
    project.samples.each { sample ->
      if (sample.fastq.isEmpty() && sample.fastq_r1.isEmpty() && sample.fastq_r2.isEmpty()) {
        exit 1, "A value in either the fastq or fastq_r1/fastq_r2 column(s) is required."
      }
      if (sample.fastq_r1.size() != sample.fastq_r2.size()) {
        exit 1, "fastq_r1 and fastq_r2 have a different number of files, use the 'fastq' column for single fastq files."
      }
      if (!sample.fastq.isEmpty() && (!sample.fastq_r1.isEmpty() || !sample.fastq_r2.isEmpty())) exit 1, "'fastq' column cannot be combined with 'fastq_r1' and/or 'fastq_r2'."
      if ((!sample.fastq_r1.isEmpty() && sample.fastq_r2.isEmpty()) || (sample.fastq_r1.isEmpty() && !sample.fastq_r2.isEmpty()))   exit 1, "Either both 'fastq_r1' and 'fastq_r2' should be present or neither should be present, use the 'fastq' column for single fastq files."
    }
  }
}
