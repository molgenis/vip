include { nrMappedReadsInChunk; getPaternalCram; getMaternalCram } from '../modules/cram/utils'
include { call; call_duo; call_trio; concat_gvcfs; concat_vcfs; joint_call;} from '../modules/cram/deepvariant'
include { hasChild; validateGroup } from '../modules/utils'
/*
 * Variant calling using DeepVariant
 *
 * input:  meta[project, family, sample, ...]
 * output: meta[project, ...                ], vcf
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
                      return [meta, [:]]
        }
      | set { ch_cram_per_chunk }
      
    // decide on variant calling method
    ch_cram_per_chunk.with_reads
      | branch { meta ->
          // samples can be included in multiple trios
          // workaround for 'nanopore', see https://github.com/google/deepvariant/issues/724
          deeptrio:    meta.project.sequencing_platform != "nanopore" && (meta.sample.paternal_id != null || meta.sample.maternal_id != null)
                       return meta
          deepvariant: meta.project.sequencing_platform == "nanopore" || (meta.sample.paternal_id == null && meta.sample.maternal_id == null && !hasChild(meta.sample, meta.family))
                       return meta
          skip:        true
                       return [meta, [:]]
        }
      | set { ch_cram_per_chunk_with_reads }

    // perform DeepVariant variant calling on cram chunks
    ch_cram_per_chunk_with_reads.deepvariant
      | map { meta -> [meta, meta.sample.cram.data, meta.sample.cram.index] }
      | call
      | map { meta, gvcf, gvcfIndex, gvcfStats -> [meta, [(meta.sample.individual_id): [data: gvcf, index: gvcfIndex, stats: gvcfStats]]] }
      | set { ch_gvcf_per_chunk_called }

    // perform DeepTrio variant calling on cram chunks
    ch_cram_per_chunk_with_reads.deeptrio
      | branch { meta ->
          // samples can be included in multiple trios
          trio:         meta.sample.paternal_id != null && meta.sample.maternal_id != null
                        return meta
          duo:          true 
                        return meta
        }
      | set { ch_cram_per_chunk_with_reads_deeptrio }


    // perform Deeptrio for trios
    ch_cram_per_chunk_with_reads_deeptrio.trio
      | map { meta -> [
                meta, meta.sample.cram.data, meta.sample.cram.index,
                getPaternalCram(meta.sample, meta.family).data, getPaternalCram(meta.sample, meta.family).index,
                getMaternalCram(meta.sample, meta.family).data, getMaternalCram(meta.sample, meta.family).index
              ]
        }
      | call_trio
      | map { meta, gvcf, gvcfIndex, gvcfStats, gvcfPaternal, gvcfIndexPaternal, gvcfStatsPaternal, gvcfMaternal, gvcfIndexMaternal, gvcfStatsMaternal -> 
          [meta, [
              (meta.sample.individual_id): [data: gvcf,         index: gvcfIndex,         stats: gvcfStats        ],
              (meta.sample.paternal_id)  : [data: gvcfPaternal, index: gvcfIndexPaternal, stats: gvcfStatsPaternal],
              (meta.sample.maternal_id)  : [data: gvcfMaternal, index: gvcfIndexMaternal, stats: gvcfStatsMaternal]
            ]
          ]
        }
      | set { ch_gvcf_per_chunk_trio_called }

    // perform Deeptrio for duo
    ch_cram_per_chunk_with_reads_deeptrio.duo
      | map { meta -> [
                meta, meta.sample.cram.data, meta.sample.cram.index,
                meta.sample.paternal_id != null ? getPaternalCram(meta.sample, meta.family).data : getMaternalCram(meta.sample, meta.family).data,
                meta.sample.paternal_id != null ? getPaternalCram(meta.sample, meta.family).index : getMaternalCram(meta.sample, meta.family).index
              ]
        }
      | call_duo
      | map { meta, gvcf, gvcfIndex, gvcfStats, gvcfPaternal, gvcfIndexPaternal, gvcfStatsPaternal -> 
          [meta, [
              (meta.sample.individual_id):                                                           [data: gvcf,         index: gvcfIndex,         stats: gvcfStats        ],
              (meta.sample.paternal_id != null ? meta.sample.paternal_id : meta.sample.maternal_id): [data: gvcfPaternal, index: gvcfIndexPaternal, stats: gvcfStatsPaternal]
            ]
          ]
        }
      | set { ch_gvcf_per_chunk_duo_called }
      
    // group gvcf chunks by project by family
    Channel.empty().mix(ch_gvcf_per_chunk_called, ch_gvcf_per_chunk_trio_called, ch_gvcf_per_chunk_duo_called, ch_cram_per_chunk.zero_reads, ch_cram_per_chunk_with_reads.skip)
      | map { meta, gvcfs -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.family.samples.size()), [sample: meta.sample, gvcfs: gvcfs]] }
      | groupTuple(remainder: true, sort: { left, right -> left.sample.index <=> right.sample.index } )
      | map { key, group -> validateGroup(key, group) }
      | set { ch_gvcf_per_chunk_per_family }
    
    // group gvcf chunks by sample
    ch_gvcf_per_chunk_per_family
      | flatMap { meta, group -> group.collect { item -> [[*:meta, sample: item.sample], group.collect { it.gvcfs[item.sample.individual_id] }.findAll { it != null } ] } }
      | branch { meta, gvcfs ->
          // samples included in multiple trios result in multiple gvcfs
          multiple: gvcfs.size() > 1
                    return [meta, gvcfs]
          single:   gvcfs.size() == 1
                    return [meta, gvcfs.first()]
          zero:     true
                    return [meta, null]
        }
      | set { ch_gvcfs_per_chunk_per_sample }

    ch_gvcfs_per_chunk_per_sample.multiple
      | map { meta, gvcfs -> [meta, gvcfs.collect { it.data }, gvcfs.collect { it.index }] }
      | concat_gvcfs
      | map { meta, gvcf, gvcfIndex, gvcfStats -> [meta, [data: gvcf, index: gvcfIndex, stats: gvcfStats]] }
      | set { ch_gvcfs_per_chunk_per_sample_merged }

    // group gvcf chunks by project
    Channel.empty().mix(ch_gvcfs_per_chunk_per_sample_merged, ch_gvcfs_per_chunk_per_sample.single, ch_gvcfs_per_chunk_per_sample.zero)
      | map { meta, gvcf -> [groupKey([*:meta].findAll { it.key != 'family' && it.key != 'sample' }, meta.project.samples.size()), [sample: meta.sample, gvcf: gvcf]] }
      | groupTuple(remainder: true, sort: { left, right -> left.sample.index <=> right.sample.index })
      | map { key, group -> validateGroup(key, group) }
      | map { meta, group -> [meta, group.collect{ it.gvcf }] }
      | set { ch_gvcfs_per_chunk_per_project }

    ch_gvcfs_per_chunk_per_project
      | branch { meta, gvcfs ->
          // joint variant calling also required for one .g.vcf
          non_zero: gvcfs.count { it != null } > 0
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
      | concat_vcfs
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_vcf_concat_by_project }

    Channel.empty().mix(ch_vcf_concat_by_project, ch_vcf_per_chunk_by_project.single, ch_vcf_per_chunk_by_project.zero)
      | set { ch_vcf_per_project }
  emit:
    ch_vcf_per_project
}

def validateCallDeepVariantParams(assemblies) {
  def glnexusWesPreset = params.snv.glnexus.WES.preset
  if (!(glnexusWesPreset ==~ /DeepVariant|DeepVariantWES|DeepVariantWES_MED_DP|DeepVariant_unfiltered/))  exit 1, "parameter 'params.snv.glnexus.WES.preset' value '${glnexusWesPreset}' is invalid. allowed values are [DeepVariant, DeepVariantWES, DeepVariantWES_MED_DP, DeepVariant_unfiltered]"

  def glnexusWgsPreset = params.snv.glnexus.WGS.preset
  if (!(glnexusWgsPreset ==~ /DeepVariant|DeepVariantWGS|DeepVariant_unfiltered/))  exit 1, "parameter 'params.snv.glnexus.WGS.preset' value '${glnexusWgsPreset}' is invalid. allowed values are [DeepVariant, DeepVariantWGS, DeepVariant_unfiltered]"
}