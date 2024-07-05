nextflow.enable.dsl=2

include { nrMappedReads } from '../modules/cram/utils'
include { spectre_call } from '../modules/cram/spectre'
include { validateGroup } from '../modules/utils'
include { merge_cnv_vcf } from '../modules/cram/merge_vcf'

/*
 * Variant calling: structural variants
 *
 * input:  meta[project, sample, ...]
 * output: meta[project, ...        ], vcf
 */
workflow cnv {
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
      | set { ch_cnv }
    
    // split channel in crams based on tool that supports sequencing platform
    ch_cnv.with_reads
      | branch { meta ->
          spectre: meta.project.sequencing_platform == 'nanopore' || meta.project.sequencing_platform == 'pacbio_hifi'
                  return meta
          ignore: true
                  return [meta, null]
        }
      | set { ch_cnv_by_platform }

    // cnv calling: spectre
    ch_cnv_by_platform.spectre
      | map { meta -> [meta, meta.sample.cram.data, meta.sample.cram.index, meta.sample.vcf.data] }
      | spectre_call
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_cnv_spectre }

    // group by project
    Channel.empty().mix(ch_cnv_spectre, ch_cnv.zero_reads, ch_cnv_by_platform.ignore)
      | map { meta, vcf -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), [sample: meta.sample, vcf: vcf]] }
      | groupTuple(remainder: true, sort: { left, right -> left.sample.index <=> right.sample.index })
      | map { key, group -> validateGroup(key, group) }
      | map { meta, group -> [[*:meta, project:[*:meta.project, samples: group.collect{it.sample}]], group.collect { it.vcf }] }
      | branch { meta, vcfs ->
          multiple: vcfs.count { it != null } > 1
                    return [meta, vcfs.findAll { it != null }]
          single:   vcfs.count { it != null } == 1
                    return [meta, vcfs.find { it != null }]
          zero:     true
                    return [meta, null]
        }
      | set { ch_cnv_by_project }

    // merge: multiple vcfs
    ch_cnv_by_project.multiple
      | map { meta, vcfs -> [meta, vcfs.collect { it.data }, vcfs.collect { it.index }] }
      | merge_cnv_vcf
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_cnv_project_merged }
    
    Channel.empty().mix(ch_cnv_project_merged, ch_cnv_by_project.single, ch_cnv_by_project.zero)
      | set { ch_cnv_processed }

    emit:
      ch_cnv_processed
}

def validateCallCnvParams(assemblies) {
  // placeholder for future parameter validation
}
