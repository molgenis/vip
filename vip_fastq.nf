nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { concat_fastq } from './modules/fastq/concat'
include { minimap2_align; minimap2_index } from './modules/fastq/minimap2'
include { cram } from './vip_cram'

//TODO instead of concat_fastq, align in parallel and merge bams (keep in mind read groups when marking duplicates)
workflow fastq {
    take: meta
    main:
        meta
            | branch { meta ->
                merge: meta.sample.fastq_r1.size() > 1 || meta.sample.fastq_r2.size() > 1
                ready: true
              }
            | set { ch_input }
        
        ch_input.merge
            | map { meta -> tuple(meta, meta.sample.fastq_r1, meta.sample.fastq_r2) }
            | concat_fastq
            | map { meta, fastq_r1, fastq_r2 -> [*:meta, sample: [*:meta.sample, fastq_r1: fastq_r1, fastq_r2: fastq_r2] ] }
            | set { ch_input_merged }

        ch_input_merged.mix(ch_input.ready)
            | map { meta -> tuple(meta, meta.sample.fastq_r1, meta.sample.fastq_r2) }
            | minimap2_align
            | map { meta, cram, cramIndex -> [*:meta, sample: [*:meta.sample, cram: cram, cram_index: cramIndex] ] }
            | cram
}

workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)

    Channel.from(sampleSheet)
        | map { sample -> [sample: sample, sampleSheet: sampleSheet] }
        | map { meta -> [*:meta, fasta_mmi: params[params.assembly].reference.fastaMmi] }
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

def validateParams() {
  validateCommonParams()
  
  def fastaMmi = params[params.assembly].reference.fastaMmi
  if(fastaMmi !== null && !file(fastaMmi).exists() )   exit 1, "parameter '${params.assembly}.reference.fastaMmi' value '${fastaMmi}' does not exist"
}

def parseSampleSheet(csvFile) {
  def fastqRegex = /.+\.(fastq|fq)(\.gz)?/

  def cols = [
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
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}

def countFamilySamples(sample, sampleSheet) {
    sampleSheet.count { thisSample -> sample.family_id == thisSample.family_id }
}