nextflow.enable.dsl=2

include { validateGroup } from '../modules/utils'
include { nrMappedReads } from '../modules/cram/utils'
include { outrider_counts; merge_sample_counts } from '../modules/rna/outrider'


workflow rna {
  take: meta
  main:
    // split channel in crams with and without mapped reads
    meta
      | branch { meta ->
          with_reads: nrMappedReads(meta.sample.cram.stats) > 0
                      return meta
          zero_reads: true
                      return [meta, null]
        }
      | set { ch_rna }
    
    ch_rna.with_reads
    | map { meta -> [meta, meta.sample.rna_cram.data, meta.sample.rna_cram.index] }
    | outrider_counts
    | map { meta, counts -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), counts] }
    | groupTuple(remainder: true, sort: { left, right -> left.sample.index <=> right.sample.index })
    | map { meta, counts -> validateGroup(meta, counts) }
    | merge_sample_counts
    //| TODO: next outrider step
    //| map
    //| set {ch_rna_processed}


    //emit:
    //  ch_rna_processed
}
