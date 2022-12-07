nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { scatter } from './modules/utils'
include { samtools_index } from './modules/cram/samtools'
include { deepvariant_call } from './modules/cram/deepvariant'
include { gvcf } from './vip_gvcf'

// TODO reintroduce trio/duo branching
workflow cram {
    take: meta
    main:
        meta
            | flatMap { meta -> scatter(meta) }
            | map { meta -> tuple(meta, meta.sample.cram, meta.sample.cram_index) }
            | deepvariant_call
            | map { meta, gVcf -> [*:meta, sample: [*:meta.sample, g_vcf: gVcf] ] }
            | gvcf
}

workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)
    //TODO deduplicate with vip_vcf
    def probands = sampleSheet.findAll{ sample -> sample.proband }.collect{ sample -> [family_id:sample.family_id, individual_id:sample.individual_id] }
    def hpo_ids = sampleSheet.collectMany { sample -> sample.hpo_ids }.unique()
    
    Channel.from(sampleSheet)
        | map { sample -> [sample: sample, sampleSheet: sampleSheet, probands: probands, hpo_ids: hpo_ids] }
        | map { meta -> [*:meta, sample: [*:meta.sample, cram_index: meta.sample.cram_index ?: findCramIndex(meta.sample.cram)]] }
        | branch { meta ->
            index: meta.sample.cram_index == null
            ready: true
        }
        | set { ch_sample }

    ch_sample.index
        | map { meta -> tuple(meta, meta.sample.cram) }
        | samtools_index
        | map { meta, cramIndex -> [*:meta, sample: [*:meta.sample, cram_index: cramIndex]] }
        | set { ch_sample_indexed }

    ch_sample_indexed.mix(ch_sample.ready)
        | cram
}

def validateParams() {
  validateCommonParams()
  validateInput()
}

def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".tsv") ) exit 1, "parameter 'input' value '${params.input}' is not a .tsv file"
}

def parseSampleSheet(csvFile) {
  def cols = [
    cram: [
      type: "file",
      required: true,
      regex: /.+\.cram/
    ],
    cram_index: [
      type: "file",
      regex: /.+\.crai/
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}

def findCramIndex(cram) {
    def cram_index
    if(file(cram + ".crai").exists()) cram_index = cram + ".crai"
    cram_index
}