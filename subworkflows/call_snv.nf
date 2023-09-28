nextflow.enable.dsl=2

include { scatter } from '../modules/utils'
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
    // split channel in cram chunks with and without mapped reads
    meta
      | flatMap { meta -> scatter(meta) }
      | set { ch_snv_chunk }

    // split channel in crams based on tool that supports sequencing platform
    ch_snv_chunk
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