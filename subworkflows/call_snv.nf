nextflow.enable.dsl=2

include { scatter; validateGroup } from '../modules/utils'
include { nrMappedReadsInChunk } from '../modules/cram/utils'
include { deepvariant; validateCallDeepVariantParams } from '../subworkflows/call_snv_deepvariant'
/*
 * Variant calling: single nucleotide variants and short insertions/deletions
 *
 * input:  meta[project, sample, ...]
 * output: meta[project, ...        ], vcf
 */
workflow snv {
  take: meta
  main:
    // add family to each sample
    meta
      | map { meta ->
          def familySize = meta.project.samples.count { it.family_id == meta.sample.family_id }
          def family = [id: meta.sample.family_id]
          return [groupKey([*:meta, family: family].findAll { it.key != 'sample' }, familySize), meta.sample]
        }
      | groupTuple(remainder: true, sort: { left, right -> left.index <=> right.index })
      | map { key, group -> validateGroup(key, group) }
      | map { meta, samples -> [*:meta, family: [*:meta.family, samples: samples]] }
      | flatMap { meta -> meta.family.samples.collect { sample -> [*:meta, sample: sample ] } }
      | set { ch_snv_family }
      
    // split channel in cram chunks with and without mapped reads
    ch_snv_family
      | flatMap { meta -> scatter(meta) }
      | set { ch_snv_family_chunk }

    // split channel in crams based on tool that supports sequencing platform
    ch_snv_family_chunk
      | branch { meta ->
          deepvariant: meta.project.sequencing_platform == 'illumina' || meta.project.sequencing_platform == 'nanopore' || meta.project.sequencing_platform == 'pacbio_hifi'
          // add new tools here
        }
      | set { ch_snv_chunk_by_platform }

    ch_snv_chunk_by_platform.deepvariant
      | deepvariant
      | set { ch_snv_deepvariant }
    
    // mix outputs of all tools
    Channel.empty().mix(ch_snv_deepvariant)
      | set { ch_snv_processed }
  emit:
    ch_snv_processed
}

def validateCallSnvParams(assemblies) {
  validateCallDeepVariantParams(assemblies)
}