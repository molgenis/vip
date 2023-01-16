nextflow.enable.dsl=2

include { validateCommonParams } from './modules/cli'
include { parseCommonSampleSheet } from './modules/sample_sheet'
include { scatter } from './modules/utils'
include { samtools_index } from './modules/cram/samtools'
include { deepvariant_call; deeptrio_call; deeptrio_call_duo_father; deeptrio_call_duo_mother } from './modules/cram/deepvariant'
include { vcf } from './vip_vcf'
include { merge_gvcf } from './modules/vcf/merge_gvcf'

workflow {
    validateParams()
    def sampleSheet = parseSampleSheet(params.input)
    
    Channel.from(sampleSheet)
        | map { sample -> [sample: sample, sampleSheet: sampleSheet] }
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

workflow cram {
    take: meta
    main:
        meta
            | map {meta -> tuple(meta.sample.family_id, meta)}
            | groupTuple(by: [0])
            | map {meta -> tuple(getFamilyStructure(meta[1]), meta)}
            | branch { meta ->
              single: meta[0] == "per_sample"
              duo_father: meta[0] == "duo_father"
              duo_mother: meta[0] == "duo_mother"
              trio: meta[0] == "trio"
            }
            | set { ch_callvariants }

            ch_callvariants.single
            | map { meta -> meta[1] }
            | flatMap { meta -> meta[1] } //from "per family" to "per sample"
            | flatMap { meta -> scatter(meta) }
            | map { meta -> tuple(meta, meta.sample.cram, meta.sample.cram_index) }
            | deepvariant_call
            | map { meta, gVcf, gVcfIndex -> [*:meta, sample: [*:meta.sample, vcf: gVcf, vcf_index: gVcfIndex] ] }
            | set { ch_deepvariant_single }

            ch_callvariants.duo_father
            | map { meta -> meta[1] }
            | map { meta -> [samples:[proband:getProbandMeta(meta[1]), father:getParentMeta(meta[1], "paternal_id")], sampleSheet:getSampleSheet(meta[1]) ] }
            | flatMap { meta -> scatter(meta) }
            | map { meta -> tuple(meta, meta.samples.proband.cram, meta.samples.proband.cram_index, meta.samples.father.cram, meta.samples.father.cram_index) }
            | deeptrio_call_duo_father
            | map { meta, gVcf, gVcfIndex, gVcfFather, gVcfFatherIndex -> [*:meta, samples: [*:meta.samples, proband: [*:meta.samples.proband, vcf: gVcf, vcf_index: gVcfIndex], father: [*:meta.samples.father, vcf: gVcfFather, vcf_index: gVcfFatherIndex] ] ] }
            | flatMap { meta -> {meta.samples.collect(entry -> [sample: entry.value, sampleSheet: meta.sampleSheet, chunk: meta.chunk]) } }
            | set { ch_deeptrio_duo_father }

            ch_callvariants.duo_mother
            | map { meta -> meta[1] }
            | map { meta -> [samples:[proband:getProbandMeta(meta[1]), father:getParentMeta(meta[1], "paternal_id")]] }
            | flatMap { meta -> scatter(meta) }
            | map { meta -> tuple(meta, meta.samples.proband.cram, meta.samples.proband.cram_index, meta.samples.mother.cram, meta.samples.mother.cram_index) }
            | deeptrio_call_duo_mother
            | map { meta, gVcf, gVcfIndex, gVcfMother, gVcfMotherIndex -> [*:meta, samples: [*:meta.samples, proband: [*:meta.samples.proband, vcf: gVcf],mother: [*:meta.samples.mother, vcf: gVcfMother, vcf_index: gVcfMotherIndex] ] ] }
            | flatMap { meta -> {meta.samples.collect(entry -> [sample: entry.value, sampleSheet: meta.sampleSheet, chunk: meta.chunk]) } }
            | set { ch_deeptrio_duo_mother }

            ch_callvariants.trio
            | map { meta -> meta[1] }
            | map { meta -> [samples:[proband:getProbandMeta(meta[1]), father:getParentMeta(meta[1], "paternal_id"), mother:getParentMeta(meta[1], "maternal_id")], sampleSheet:getSampleSheet(meta[1]) ] }
            | flatMap { meta -> scatter(meta) }
            | map { meta -> tuple(meta, meta.samples.proband.cram, meta.samples.proband.cram_index, meta.samples.mother.cram, meta.samples.mother.cram_index) }
            | deeptrio_call
            | map { meta, gVcf, gVcfIndex, gVcfFather, gVcfFatherIndex, gVcfMother, gVcfMotherIndex -> [*:meta, samples: [*:meta.samples, proband: [*:meta.samples.proband, vcf: gVcf, vcf_index: gVcfIndex], mother: [*:meta.samples.mother, vcf: gVcfMother, vcf_index: gVcfMotherIndex], father: [*:meta.samples.father, vcf: gVcfFather, vcf_index: gVcfFatherIndex] ] ] }
            | flatMap { meta -> {meta.samples.collect(entry -> [sample: entry.value, sampleSheet: meta.sampleSheet, chunk: meta.chunk]) } }
            | set { ch_deeptrio_trio }
            
            ch_deepvariant_single.mix(ch_deeptrio_duo_father).mix(ch_deeptrio_duo_mother).mix(ch_deeptrio_trio)
            | set { ch_gvcf }

            //FIXME merge per project instead of per samplesheet
            ch_gvcf
              | map { meta ->
                def groupSize = meta.sampleSheet.count{ sample -> sample.vcf != null }
                tuple(groupKey(meta.chunk.index, groupSize), meta)
                }
            | groupTuple
            | map { key, group -> tuple([group: group, chunk: group.first().chunk], group.collect(meta -> meta.sample.vcf), group.collect(meta -> meta.sample.vcf_index)) }
            | merge_gvcf
            | map { meta, vcf, vcfIndex, vcfStats -> 
                def newMeta = [*:meta.group.first(), vcf: vcf, vcf_index: vcfIndex, vcf_stats: vcfStats]
                newMeta.remove('sample')
                return newMeta
              }
            | vcf
}

def getFamilyStructure(meta) {
  def probands = [];
  meta.forEach(object -> {
    if(object.sample.proband){
      probands.add(object.sample)
    }
  })

  def fatherCram
  def motherCram
  if(probands.size() == 1){
    meta.forEach(object -> {
      if(object.sample.individual_id == probands[0].paternal_id){
        fatherCram = object.sample.cram
      }
      if(object.sample.individual_id == probands[0].maternal_id){
        motherCram = object.sample.cram
      }
    })
  }
  if(motherCram && fatherCram){
    return "trio"
  }
  else if(motherCram && !fatherCram){
    return "duo_mother"
  }
  else if(!motherCram && fatherCram){
    return "duo_father"
  }
  return "per_sample"
}

def getProbandMeta(meta) {
  meta.forEach(object -> {
      if(object.sample.proband){
        sampleMeta = object.sample
        return
      }
    }
  )
  sampleMeta
}

def getParentMeta(meta, field) {
  def parentMeta
  def proband
  meta.forEach(object -> {
    if(object.sample.proband){
      proband = object.sample
      return
    }
  })
  meta.forEach(object -> {
    if(object.sample.individual_id == proband[field]){
      parentMeta = object.sample
    }
  })
  parentMeta
}

def getSampleSheet(meta) {
  meta.forEach(object -> {
      if(object.sample.proband){
        sampleSheet = object.sampleSheet
        return
      }
    }
  )
  sampleSheet
}

def validateParams() {
  validateCommonParams()
}

def parseSampleSheet(csvFile) {
  def cols = [
    cram: [
      type: "file",
      required: true,
      regex: /.+\.cram/
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}

def findCramIndex(cram) {
    def cram_index
    if(file(cram + ".crai").exists()) cram_index = cram + ".crai"
    cram_index
}