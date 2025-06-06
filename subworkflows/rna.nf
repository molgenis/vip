nextflow.enable.dsl=2

include { validateGroup } from '../modules/utils'
include { nrMappedReads } from '../modules/cram/utils'
include { outrider_counts; outrider_create_dataset; outrider_optimize; outrider } from '../modules/rna/outrider'
include { fraser; fraserCount } from '../modules/rna/fraser'


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
      | multiMap { it -> outrider: fraser: it }
      | set { ch_process_rna }

  ch_process_rna.outrider
    | outrider_counts
    | map { meta, counts -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), counts] }
    | groupTuple(remainder: true, sort: { left, right -> left.sample.index <=> right.sample.index })
    | map { meta, counts -> validateGroup(meta, counts) }
    | outrider_create_dataset
    | flatMap { meta, outriderDataset, qvalues -> 
        qvalues
            .splitCsv(header: false, sep: '\t')
            .collect { row -> tuple(meta, outriderDataset, qvalues, row[0])}
        }
    | outrider_optimize
    | map { meta, dataset, qvalues, counts -> 
      {
        return [groupKey(meta, qvalues.readLines().size()), dataset, counts] 
      }
    }
    | groupTuple
    | map { key,datasets,endims -> [key, datasets[0], endims]}
    | outrider
    //| map to meta, outrider_file
    //| set {ch_rna_processed}

 ch_process_rna.fraser
 //   |fraserCount
//    |fraser

    //emit:
    //  ch_rna_processed
}
