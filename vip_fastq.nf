nextflow.enable.dsl=2

include { parseCommonSampleSheet } from './modules/sample_sheet'
include { getBedRegex } from './modules/utils'
include { fastp; fastp_paired_end } from './modules/fastq/fastp'
include { filter_reads } from './modules/fastq/adaptive_sampling'
include { minimap2_align; minimap2_align_paired_end } from './modules/fastq/minimap2'
include { cram; validateCramParams } from './vip_cram'

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
      | map { meta -> [meta, meta.sample.fastq_r1, meta.sample.fastq_r2] }
      | fastp_paired_end
      | set { ch_fastp_paired_end }

    ch_fastp_paired_end.reads_pass
      | minimap2_align_paired_end
      | set { ch_input_paired_end_aligned }

    // single fastq
    ch_input.single
      | branch { meta ->
          filter: meta.sample.adaptive_sampling != null
                  return meta
          ready: true
                  return [meta, meta.sample.fastq]
        }
      | set { ch_input_single_branch }

    ch_input_single_branch.filter
      | map { meta -> [meta, meta.sample.fastq, meta.sample.adaptive_sampling] }
    	| filter_reads
      | set { ch_input_single_filtered }

    Channel.empty().mix(ch_input_single_filtered, ch_input_single_branch.ready)
      | fastp
      | set { ch_fastp }

    ch_fastp.reads_pass  
      | minimap2_align
      | set { ch_input_single_aligned }

    // mix paired-end and single channels
    ch_input_paired_end_aligned.mix(ch_input_single_aligned)
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
    adaptive_sampling: [
      type: "file",
      regex: /.+\.csv/
    ],
    fastq: [
      type: "file",
      list: true,
      regex: fastqRegex
    ],
    fastq_r1: [
      type: "file",
      list: true,
      regex: fastqRegex
    ],
    fastq_r2: [
      type: "file",
      list: true,
      regex: fastqRegex
    ],
    sequencing_platform: [
      type: "string",
      default: { 'illumina' },
      enum: ['illumina', 'nanopore', 'pacbio_hifi'],
      scope: "project"
    ],
    bed: [
      type: "file",
      scope: "project",
      regex: getBedRegex()
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
      if (sample.adaptive_sampling != null && project.sequencing_platform != 'nanopore') exit 1, "'adaptive_sampling' column cannot be used for sequencing_platform other than 'nanopore'."
      if (sample.adaptive_sampling != null && (!sample.fastq_r1.isEmpty() || !sample.fastq_r2.isEmpty())) exit 1, "'adaptive_sampling' column cannot be combined with 'fastq_r1' and/or 'fastq_r2'."
    }
  }
}
