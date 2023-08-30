nextflow.enable.dsl=2

include { scatter } from '../modules/utils'
include { nrMappedReadsInChunk } from '../modules/cram/utils'
include { clair3; validateCallClair3Params } from '../subworkflows/call_snv_clair3'
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
          clair3: meta.project.sequencing_platform == 'illumina' || meta.project.sequencing_platform == 'nanopore' || meta.project.sequencing_platform == 'pacbio_hifi'
          // add new tools here
        }
      | set { ch_snv_chunk_by_platform }

    // clair3: perform snv calling on cram chunks with mapped reads
    ch_snv_chunk_by_platform.clair3
      | clair3
      | set { ch_snv_clair3 }
    
    // mix outputs of all tools
    Channel.empty().mix(ch_snv_clair3)
      | set { ch_snv_processed }
  emit:
    ch_snv_processed
}

def validateCallSnvParams(assemblies) {
  validateCallClair3Params(assemblies)
}