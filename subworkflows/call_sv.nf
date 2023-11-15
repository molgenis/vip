nextflow.enable.dsl=2

include { nrMappedReads } from '../modules/cram/utils'
include { cutesv_call } from '../modules/cram/cutesv'
include { manta_joint_call } from '../modules/cram/manta'
include { merge_sv_vcf } from '../modules/cram/merge_vcf'
include { validateGroup } from '../modules/utils'

/*
 * Variant calling: structural variants
 *
 * input:  meta[project, sample, ...]
 * output: meta[project, ...        ], vcf
 */
workflow sv {
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
      | set { ch_sv }
    
    // split channel in crams based on tool that supports sequencing platform
    ch_sv.with_reads
      | branch { meta ->
          cutesv: meta.project.sequencing_platform == 'nanopore' || meta.project.sequencing_platform == 'pacbio_hifi'
                  return meta
          // manta requires paired-end reads but we can't detect whether that is the case when starting with the cram workflow
          manta:  meta.project.sequencing_platform == 'illumina'
                  return meta
          ignore: true
                  return [meta, null]
        }
      | set { ch_sv_by_platform }

    // sv calling: cutesv
    ch_sv_by_platform.cutesv
      | map { meta -> [meta, meta.sample.cram.data, meta.sample.cram.index] }
      | cutesv_call
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_sv_cutesv }

    // sv calling: manta
    ch_sv_by_platform.manta
      | map { meta -> [meta, [data: meta.sample.cram.data, index: meta.sample.cram.index]] }
      | map { meta, cram -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), [sample: meta.sample, cram: cram]] }
      | groupTuple(remainder: true, sort: { left, right -> left.sample.index <=> right.sample.index })
      | map { key, group -> validateGroup(key, group) }
      | map { meta, group -> [[*:meta, project:[*:meta.project, samples: group.collect{it.sample}]], group.collect { it.cram }] }
      | map { meta, crams -> [meta, crams.collect { it.data }, crams.collect { it.index }] }
      | manta_joint_call
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_sv_manta }

    // group by project
    Channel.empty().mix(ch_sv_cutesv, ch_sv.zero_reads, ch_sv_by_platform.ignore)
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
      | set { ch_sv_by_project }

    // merge: multiple vcfs
    ch_sv_by_project.multiple
      | map { meta, vcfs -> [meta, vcfs.collect { it.data }, vcfs.collect { it.index }] }
      | merge_sv_vcf
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_sv_project_merged }
    
    Channel.empty().mix(ch_sv_project_merged, ch_sv_by_project.single, ch_sv_by_project.zero, ch_sv_manta)
      | set { ch_sv_processed }

    emit:
      ch_sv_processed
}

def validateCallSvParams(assemblies) {
  // placeholder for future parameter validation
}
