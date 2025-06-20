nextflow.enable.dsl=2

include { validateGroup } from '../modules/utils'
include { nrMappedReads } from '../modules/cram/utils'
include { outrider_counts; outrider_create_dataset; outrider_optimize; outrider } from '../modules/rna/outrider'
include { fraser; fraser_counts } from '../modules/rna/fraser'


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
      | view {meta, data, index -> data}
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
    | map { meta, outrider -> [meta.project.id, meta, outrider]}
    | set {ch_rna_outrider_processed}

 ch_process_rna.fraser
    | map { meta, bam, bai -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), [bam: bam, bai: bai]] }
    | groupTuple(remainder: true, sort: { left, right -> left.index <=> right.index })
    | map { key, group -> validateGroup(key, group) }
    | map { meta, group ->
        def bams = group.collect { it.bam }
        def bais = group.collect { it.bai }
        [meta, bams, bais]
    }
    | fraser_counts
    | fraser
    | map { meta, fraser -> [meta.project.id, meta, fraser]}
    | set { ch_rna_fraser_processed }


    ch_rna_outrider_processed
    | join ( ch_rna_fraser_processed )
    | map { key,meta1,outrider,meta2,fraser -> [meta1, outrider, fraser]}
    | set { ch_rna_processed }

    emit:
      ch_rna_processed
}
