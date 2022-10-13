nextflow.enable.dsl=2

include { parseSampleSheet } from './modules/prototype/sample_sheet'
include { minimap2_align } from './modules/prototype/minimap2'
include { samtools_idxstats; parseAlignmentStats; parseFastaIndex } from './modules/prototype/samtools'
include { deepvariant_call; deeptrio_call; deeptrio_call_duo_father; deeptrio_call_duo_mother } from './modules/prototype/deepvariant'
include { glnexus_merge } from './modules/prototype/glnexus'
include { bcftools_concat; bcftools_concat_index; bcftools_view_contig } from './modules/prototype/bcftools'
include { vcf_report_create } from './modules/prototype/vcf_report'
include { validate } from './modules/prototype/cli'

workflow {
  validate()

  def reference = params.reference
  def referenceFai = params.reference + ".fai"
  def referenceGzi = params.reference + ".gzi"
  def referenceMmi = params.reference + ".mmi"

  def sampleSheet = parseSampleSheet(params.input)
  // FIXME calculate from sample sheet
  def nrSamples = 9
  def contigs = parseFastaIndex(referenceFai)
 
  sample_ch = Channel.from(sampleSheet.entrySet()) \
    | flatMap { it.value.values() }

  sample_ch \
    | branch {
        skip: it.cram != null && it.cram_index != null
        process: true
      }
    | set { align_ch }

  /*
    step #1 alignment
  */
  align_ch.skip \
    | map { sample -> [sample: sample, cram: sample.cram, cram_index: sample.cram_index] }
    | set { align_skipped_ch }

  align_ch.process \
    | map { sample -> tuple(sample, reference, referenceFai, referenceGzi, referenceMmi) }
    | minimap2_align
    | map { sample, cram, cramCrai -> [sample: sample, cram: cram, cram_index: cramCrai] }
    | set { align_processed_ch }

  aligned_ch = align_processed_ch.mix(align_skipped_ch)
  
  /*
    step #2 variant calling
  */
  aligned_ch \
    | branch { meta -> 
        skip: meta.sample.g_vcf != null && meta.sample.g_vcf_index != null
        process: true
      }
    | set { variant_call_ch }

  // FIXME hardcoded nr_contigs, chr21, chr22
  variant_call_ch.skip \
    | flatMap { meta -> contigs.collect { contig -> [*:meta, contig: contig, nr_contigs: 2] } }
    | filter { meta -> meta.contig == "chr22" || meta.contig == "chr23" }
    | map { meta -> tuple(meta, meta.sample.g_vcf, meta.sample.g_vcf_index) }
    | bcftools_view_contig
    | map { meta, gVcf -> [*:meta, gVcf: gVcf] }
    | set { variant_call_skipped_ch }
  
  // TODO improvement: set nr_family_samples in sample_ch instead of sampleSheet[meta.sample.family_id].size())
  // FIXME remove (contig == "chr21" || contig == "chr22")
  variant_call_ch.process \
    | map { meta -> tuple(groupKey(meta.sample.family_id, sampleSheet[meta.sample.family_id].size()), meta) }
    | groupTuple
    | flatMap { key, group -> group.collect { [*:it, family: group.collectEntries{ meta -> [meta.sample.individual_id, meta] }] } }
    | filter { meta -> meta.sample.proband }
    | map { meta -> tuple(meta, meta.cram, meta.cram_index) }
    | samtools_idxstats
    | flatMap { meta, statsFile ->
        def stats = parseAlignmentStats(statsFile)
        def contigsWithReads = contigs.findAll { (it == "chr21" || it == "chr22") && (stats[it].nrMappedReads + stats[it].nrUnmappedReads > 0) }
        contigsWithReads.collect { contig -> [*:meta, contig: contig, nr_contigs: contigsWithReads.size()] }
      }
    | branch { meta ->
        trio: meta.sample.paternal_id != null && meta.sample.maternal_id != null
        duoFather: meta.sample.paternal_id != null && meta.sample.maternal_id == null
        duoMother: meta.sample.paternal_id == null && meta.sample.maternal_id != null
        single: true
      }
    | set { variant_call_branch_ch } 
  
  variant_call_branch_ch.trio
    | map { meta -> tuple(meta, reference, referenceFai, referenceGzi,
          meta.cram, meta.cram_index,
          meta.family[meta.sample.paternal_id].cram, meta.family[meta.sample.paternal_id].cram_index,
          meta.family[meta.sample.maternal_id].cram, meta.family[meta.sample.maternal_id].cram_index)
      }
    | deeptrio_call
    | flatMap { meta, gVcf, gVcfFather, gVcfMother -> [[*:meta, gVcf: gVcf], [*:meta.family[meta.sample.paternal_id], gVcf: gVcfFather, contig: meta.contig, nr_contigs: meta.nr_contigs], [*:meta.family[meta.sample.maternal_id], gVcf: gVcfMother, contig: meta.contig, nr_contigs: meta.nr_contigs]] }
    | set { variant_call_trio_processed_ch }

  variant_call_branch_ch.duoFather
    | map { meta -> tuple(meta,
          reference, referenceFai, referenceGzi,
          meta.cram, meta.cram_index,
          meta.family[meta.sample.paternal_id].cram, meta.family[meta.sample.paternal_id].cram_index)
      }
    | deeptrio_call_duo_father
    | flatMap { meta, gVcf, gVcfFather -> [[*:meta, gVcf: gVcf], [*:meta.family[meta.sample.paternal_id], gVcf: gVcfFather, contig: meta.contig, nr_contigs: meta.nr_contigs]] }
    | set { variant_call_duoFather_processed_ch }

  variant_call_branch_ch.duoMother
    | map { meta -> tuple(meta,
          reference, referenceFai, referenceGzi,
          meta.cram, meta.cram_index,
          meta.family[meta.sample.maternal_id].cram, meta.family[meta.sample.maternal_id].cram_index)
      }
    | deeptrio_call_duo_mother
    | flatMap { meta, gVcf, gVcfMother -> [[*:meta, gVcf: gVcf], [*:meta.family[meta.sample.maternal_id], gVcf: gVcfMother, contig: meta.contig, nr_contigs: meta.nr_contigs]] }
    | set { variant_call_duoMother_processed_ch }

  variant_call_branch_ch.single \
    | map { meta -> tuple(meta,
          reference, referenceFai, referenceGzi,
          meta.cram, meta.cram_index)
      }
    | deepvariant_call
    | map { meta, gVcf -> [ *:meta, gVcf: gVcf ] }
    | set { variant_call_other_processed_ch }

  variant_called_ch = variant_call_skipped_ch.mix(
      variant_call_trio_processed_ch,
      variant_call_duoFather_processed_ch,
      variant_call_duoMother_processed_ch,
      variant_call_other_processed_ch
    )

  /*
    step #3 .g.vcf to .bcf  
  */
  variant_called_ch
    | map { meta -> tuple(groupKey(meta.contig, nrSamples), meta) }
    | groupTuple
    | map { key, group -> tuple([contig: key, samples: group], group.collect(meta -> meta.gVcf)) }
    | glnexus_merge
    | map { meta, bcf -> [*:meta, bcf: bcf] }
    | set { bcf_region_ch }

  /*
    step #4 .bcf to .html
  */
  // TODO split in subworkflows
  // FIXME doesn't work when some duo/trio samples have gVCF while others have not
  // TODO add derived sample data in wrapper object, do not edit sample row e.g. {sample: {...}], family: {...}, regions: { contig: <...>, start: <...>, stop: <...> }}, gVcf: <...> }
  // TODO nanopore
  // TODO mantasv
  // TODO report probands
  // TODO report pedigree
  // TODO report crams
  // TODO report genes
  // TODO report phenotypes from sample sheet
  bcf_region_ch 
    | toSortedList { thisMeta, thatMeta -> contigs.findIndexOf{ it == thatMeta.contig } <=> contigs.findIndexOf{ it == thisMeta.contig } }
    | map { metaList -> tuple(metaList, metaList.collect{ meta -> meta.bcf }) }
    | bcftools_concat
    | map { metaList, vcf -> tuple(metaList, vcf, params.reference, referenceFai, referenceGzi) }
    | vcf_report_create

  // TODO start from vcf
  // TODO publish result
  // TODO publish intermediate results
}
