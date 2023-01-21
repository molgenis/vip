nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { concat_fastq; concat_fastq_paired_end } from './modules/fastq/concat'
include { minimap2_align; minimap2_align_paired_end; minimap2_index } from './modules/fastq/minimap2'
include { cram } from './vip_cram'

//TODO instead of concat_fastq, align in parallel and merge bams (keep in mind read groups when marking duplicates)
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
            | map { meta, cram, cramIndex -> [*:meta, sample: [*:meta.sample, cram: cram, cram_index: cramIndex] ] }
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
            | map { meta, cram, cramIndex -> [*:meta, sample: [*:meta.sample, cram: cram, cram_index: cramIndex] ] }
            | set { ch_input_single_aligned }

        // merge
        ch_input_paired_end_aligned.mix(ch_input_single_aligned)
            | cram
}

workflow {
    def sampleSheet = parseSampleSheet(params.input)
    validateParams(sampleSheet)

    Channel.from(sampleSheet)
        | map { sample -> [sample: sample, sampleSheet: sampleSheet] }
        | map { meta -> [*:meta, fasta_mmi: params[params.sample.assembly].reference.fastaMmi] }
        | branch { meta ->
            index: meta.fasta_mmi == null
            ready: true
        }
        | set { ch_index }

    ch_index.index
        | minimap2_index
        | map { meta, fasta_mmi -> [*:meta, fasta_mmi: fasta_mmi] }
        | set { ch_index_indexed }

    ch_index_indexed.mix(ch_index.ready)
    | fastq
}

def validateParams(sampleSheet) {
  def assemblies = getAssemblies(sampleSheet)
  
  validateCommonParams(assemblies)
  
  assemblies.each { assembly ->
    def fastaMmi = params[assembly].reference.fastaMmi
    if(!fastaMmi.isEmpty() && !file(fastaMmi).exists() )   exit 1, "parameter '${assembly}.reference.fastaMmi' value '${fastaMmi}' does not exist"
  }  
}

def parseSampleSheet(csvFile) {
  def fastqRegex = /.+\.(fastq|fq)(\.gz)?/

  // TODO implement constraint: either fastq or fastq_r1/fastq_r2 must have a value
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
    sequencing_platform: [
      type: "string",
      default: 'illumina'
      enum: ['illumina', 'nanopore']
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}
