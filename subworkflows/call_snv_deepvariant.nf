include { nrMappedReadsInChunk } from '../modules/cram/utils'
include { call; concat; joint_call;} from '../modules/cram/deepvariant'

/*
 * Variant calling using DeepVariant
 *
 * input:  meta[project, sample, ...]
 * output: meta[project, ...        ], vcf
 */
workflow deepvariant {
  take: meta
  main:
    // determine for which chunks variant calling is possible
    meta
      | branch { meta ->
          with_reads: nrMappedReadsInChunk(meta.chunk, meta.sample.cram.stats) > 0
                      return meta
          zero_reads: true
                      return [meta, null]
        }
      | set { ch_cram_per_chunk }

    // perform variant calling on cram chunks
    ch_cram_per_chunk.with_reads
      | map { meta -> [meta, meta.sample.cram.data, meta.sample.cram.index] }
      | call
      | map { meta, gvcf, gvcfIndex, gvcfStats -> [meta, [data: gvcf, index: gvcfIndex, stats: gvcfStats]] }
      | set { ch_gvcf_per_chunk_called }

    // group .g.vcfs chunks by project
    Channel.empty().mix(ch_gvcf_per_chunk_called, ch_cram_per_chunk.zero_reads)
      | map { meta, gvcf -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), [index: meta.sample.index, gvcf: gvcf]] }
      | groupTuple
      | map { key, group -> [key.getGroupTarget(), group.sort { left, right -> left.index <=> right.index }.collect { it.gvcf }] }
      | branch { meta, gvcfs ->
          non_zero: gvcfs.count { it != null } > 0 // joint variant calling also required for one .g.vcf
                    return [meta, gvcfs.findAll { it != null }]
          zero:     true
                    return [meta, null]
        }
      | set { ch_gvcf_per_chunk_by_project }
    
    // joint variant calling per project, per chunk: one or more gvcfs
    ch_gvcf_per_chunk_by_project.non_zero
      | map { meta, gvcfs -> [meta, gvcfs.collect { it.data }, gvcfs.collect { it.index }] }
      | joint_call
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_vcf_per_chunk_called }
 
    // group chunked vcfs by project
    Channel.empty().mix(ch_vcf_per_chunk_called, ch_gvcf_per_chunk_by_project.zero)
      | map { meta, vcf -> [groupKey([*:meta].findAll { it.key != 'chunk' }, meta.chunk.total), [index: meta.chunk.index, vcf: vcf]] }
      | groupTuple
      | map { key, group -> [key.getGroupTarget(), group.sort { left, right -> left.index <=> right.index }.collect { it.vcf } ] }
      | branch { meta, vcfs ->
          multiple: vcfs.count { it != null } > 1
                    return [meta, vcfs.findAll { it != null }]
          single:   vcfs.count { it != null } == 1
                    return [meta, vcfs.find { it != null }]
          zero:     true
                    return [meta, null]
        }
      | set { ch_vcf_per_chunk_by_project }
    
    // concatenate chunked vcfs by project
    ch_vcf_per_chunk_by_project.multiple
      | map { meta, vcfs -> [meta, vcfs.collect { it.data }, vcfs.collect { it.index }] }
      | concat
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_vcf_concat_by_project }

    Channel.empty().mix(ch_vcf_concat_by_project, ch_vcf_per_chunk_by_project.single, ch_vcf_per_chunk_by_project.zero)
      | set { ch_vcf_per_project }
  emit:
    ch_vcf_per_project
}

def validateCallDeepVariantParams(assemblies) {
  // placeholder for future parameter validation
}