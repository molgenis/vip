nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { concat_fastq } from './modules/fastq/concat'
include { minimap2_align } from './modules/fastq/minimap2'
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

//TODO make .mmi optional
workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)
    //FIXME calculate probands and hpo_ids per project
    def probands = sampleSheet.findAll{ sample -> sample.proband }.collect{ sample -> [family_id:sample.family_id, individual_id:sample.individual_id] }
    def hpo_ids = sampleSheet.collectMany { sample -> sample.hpo_ids }.unique()

    Channel.from(sampleSheet)
    | map { sample -> [sample: sample, sampleSheet: sampleSheet, probands: probands, hpo_ids: hpo_ids] }
    | fastq
}

def validateParams() {
  validateCommonParams()
  validateReferenceMmi()
}

def validateReferenceMmi() {
  def assembly = params[params.assembly]
  def referenceMmi = assembly.reference.fastaMmi
  if( !file(referenceMmi).exists() )   exit 1, "parameter '${assembly}.reference.fastaMmi' value '${referenceMmi}' does not exist"
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