nextflow.enable.dsl=2

include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { concat_fastq; concat_fastq_paired_end } from './modules/fastq/concat'
include { minimap2_align; minimap2_align_paired_end } from './modules/fastq/minimap2'
include { cram; validateCramParams } from './vip_cram'
include { trimmomatic_pe; trimmomatic_se } from './modules/fastq/Trimmomatic.nf'
include { star_pe; star_se; samtools } from './modules/fastq/STAR.nf'


/**
 * input:  [project, sample [...      ], ...]
 * output: [project, sample [cram, ...], ...]
 */
workflow fastq {
  take: meta
  main:
    //TODO instead of concat_fastq, align in parallel and merge bams (keep in mind read groups when marking duplicates)
    
    // branch samples containg RNA data from the rest
    meta
      | branch { meta ->
          rna: !meta.sample.fastq_rna.isEmpty() || !meta.sample.fastq_rna_r1.isEmpty()
          ready: true
        }
      | set { ch_split }

    // create an empty RNA variable if no RNA fastqs are given
    ch_split.ready
      | map { meta -> [*:meta, project:[*:meta.project, samples:[[*:meta.project.samples[0], rna:""]]] ] }
      | set { ch_dna_only }

    // check if input is paired end or single end, split in two groups
    ch_split.rna
      | branch { meta ->
          paired_end: !meta.sample.fastq_rna_r1.isEmpty() && !meta.sample.fastq_rna_r2.isEmpty()
          single: true
        }
      | set { ch_rna }

    // process paired end RNA data
    ch_rna.paired_end
      | map { meta -> [meta, meta.sample.fastq_rna_r1, meta.sample.fastq_rna_r2, meta.sample.individual_id] }
      | trimmomatic_pe
      | star_pe
      | set { ch_rna_pe_done}

    // process single end RNA data
    ch_rna.single
      | map { meta -> [meta, meta.sample.fastq_rna, meta.sample.individual_id] }
      | trimmomatic_se
      | star_se
      | set { ch_rna_se_done }

    // finalize the created bam file and add it in the right variable
    ch_rna_pe_done.mix(ch_rna_se_done)
      | samtools
      | map { meta, rna_bam -> [*:meta, project:[*:meta.project, samples:[[*:meta.project.samples[0], rna:rna_bam]]] ]}
      | set { ch_rna_done }

    // return to DNA data
    ch_rna_done
      | branch { meta ->
          paired_end: !meta.sample.fastq_r1.isEmpty() && !meta.sample.fastq_r2.isEmpty()
          single: true
        }
      | set { ch_input }
    
    // paired-end fastq
    ch_input.paired_end
      | branch { meta ->
          merge: meta.sample.fastq_r1.size() > 1 || meta.sample.fastq_r2.size() > 1
          ready: true
        }
      | set { ch_input_paired_end }
    
    ch_input_paired_end.merge
      | map { meta -> tuple(meta, meta.sample.fastq_r1, meta.sample.fastq_r2) }
      | concat_fastq_paired_end
      | map { meta, fastq_r1, fastq_r2 -> [*:meta, sample: [*:meta.sample, fastq_r1: fastq_r1, fastq_r2: fastq_r2] ] }
      | set { ch_input_paired_end_merged }

    ch_input_paired_end_merged.mix(ch_input_paired_end.ready)
      | map { meta -> tuple(meta, meta.sample.fastq_r1, meta.sample.fastq_r2) }
      | minimap2_align_paired_end
      | set { ch_input_paired_end_aligned }
    
    // single fastq
    ch_input.single
      | branch { meta ->
          merge: meta.sample.fastq.size() > 1
          ready: true
        }
      | set { ch_input_single }
    
    ch_input_single.merge
      | map { meta -> tuple(meta, meta.sample.fastq) }
      | concat_fastq
      | map { meta, fastq -> [*:meta, sample: [*:meta.sample, fastq: fastq] ] }
      | set { ch_input_single_merged }

    ch_input_single_merged.mix(ch_input_single.ready)
      | map { meta -> tuple(meta, meta.sample.fastq) }
      | minimap2_align
      | set { ch_input_single_aligned }

    // merge
    Channel.empty().mix(ch_input_paired_end_aligned, ch_input_single_aligned)
      | map { meta, cram, cramIndex, cramStats -> [*:meta, sample: [*:meta.sample, cram: [data: cram, index: cramIndex, stats: cramStats]]] }
      | cram
}

workflow {
  def projects = parseSampleSheet(params.input)
  def assemblies = getAssemblies(projects)
  validateFastqParams(assemblies)

  // run fastq workflow for each sample in each project
  Channel.from(projects)
    | flatMap { project -> project.samples.collect { sample -> [project: project, sample: sample] } }
    | fastq
}

def validateFastqParams(assemblies) {
  validateCramParams(assemblies)
  
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
    fastq_rna: [
      type: "file",
      list: true,
      regex: fastqRegex
    ],
    fastq_rna_r1: [
      type: "file",
      list: true,
      regex: fastqRegex
    ],
    fastq_rna_r2: [
      type: "file",
      list: true,
      regex: fastqRegex
    ],
    sequencing_platform: [
      type: "string",
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
      if (!sample.fastq.isEmpty() && (!sample.fastq_r1.isEmpty() || !sample.fastq_r2.isEmpty())) exit 1, "'fastq' column cannot be combined with 'fastq_r1' and/or 'fastq_r2'."
      if ((!sample.fastq_r1.isEmpty() && sample.fastq_r2.isEmpty()) || (sample.fastq_r1.isEmpty() && !sample.fastq_r2.isEmpty()))   exit 1, "Either both 'fastq_r1' and 'fastq_r2' should be present or neither should be present, use the 'fastq' column for single fastq files."
    }
  }
}
