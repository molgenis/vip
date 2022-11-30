nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { findTabixIndex; scatter } from './modules/utils'
include { glnexus_merge } from './modules/gvcf/glnexus'
include { bcftools_index; bcftools_view_chunk } from './modules/vcf/bcftools'
include { vip_vcf } from './vip_vcf'

// FIXME replace hardcoded nrSamples=1 with nrSamples_that_have_data derived from sample sheet
workflow vip_gvcf {
    take: meta
    main:
        meta
            | map { meta -> tuple(groupKey(meta.chunk.index, 1), meta) }
            | groupTuple
            | map { key, group -> tuple([samples: group.collect(meta -> meta.sample), chunk: group.first().chunk], group.collect(meta -> meta.sample.g_vcf)) }
            | glnexus_merge
            | map { meta, vcf, vcfIndex -> [*:meta, vcf: vcf, vcf_index: vcfIndex] }
            | vip_vcf
}

workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)
    //TODO deduplicate with vip_vcf
    def probands = sampleSheet.findAll{ sample -> sample.proband }.collect{ sample -> [family_id:sample.family_id, individual_id:sample.individual_id] }
    def hpo_ids = sampleSheet.collectMany { sample -> sample.hpo_ids }.unique()

    Channel.from(sampleSheet)
        | map { sample -> [sample: sample, sampleSheet: sampleSheet, probands: probands, hpo_ids: hpo_ids] }
        | map { meta -> [*:meta, sample: [*:meta.sample, g_vcf_index: meta.sample.g_vcf_index ?: findTabixIndex(meta.sample.g_vcf)]] }
        | branch { meta ->
            index: meta.sample.g_vcf_index == null
            ready: true
          }
        | set { ch_sample }

    ch_sample.index
        | map { meta -> tuple(meta, meta.sample.g_vcf) }
        | bcftools_index
        | map { meta, gVcfIndex -> [*:meta, sample: [*:meta.sample, g_vcf_index: gVcfIndex]] }
        | set { ch_sample_indexed }

    ch_sample_indexed.mix(ch_sample.ready)
        | flatMap { meta -> scatter(meta) }
        | map { meta -> tuple(meta, meta.sample.g_vcf, meta.sample.g_vcf_index) }
        | bcftools_view_chunk
        | map { meta, gVcfChunk, gVcfChunkIndex -> [*:meta, sample: [*:meta.sample, g_vcf: gVcfChunk, g_vcf_index: gVcfChunkIndex]] }
        | vip_gvcf
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
    g_vcf: [
      type: "file",
      required: true,
      regex: /.+\.g\.vcf\.gz/
    ],
    g_vcf_index: [
      type: "file",
      regex: /.+\.g\.vcf\.gz\.(csi|tbi)/
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}