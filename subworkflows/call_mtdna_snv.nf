nextflow.enable.dsl=2

include { nrMappedReads } from '../modules/cram/utils'
include { mutect2_mito } from '../modules/cram/gatk.nf'
include { merge_mtdnasnv_vcf } from '../modules/cram/merge_vcf.nf'
include { publish_vcf } from '../modules/cram/publish_vcf.nf'
include { validateGroup } from '../modules/utils'
// include {call} from '../modules/cram/deepvariant.nf'

workflow mtdnasnv {
  take: meta
  main:
    // Split the channel in crams with mapped and without mapped reads
    meta
      | branch { meta ->
          with_reads: nrMappedReads(meta.sample.cram.chrmstats) > 0
                      return meta
          zero_reads: true
                      return meta
        }
      | set { ch_mtdnasnv }

    // Perform the GATK Mutect2 calling on chrM data
    ch_mtdnasnv.with_reads
      | map { meta -> [meta, meta.sample.cram.chrmdata, meta.sample.cram.chrmindex] }
      | mutect2_mito
      | map { meta, vcfOut, vcfOutIndex, vcfOutStats -> [meta, [data: vcfOut, index: vcfOutIndex, stats: vcfOutStats]] }
      | set { ch_mtdnasnv_gatk }

    // Group the vcfs per project
    Channel.empty().mix(ch_mtdnasnv_gatk, ch_mtdnasnv.zero_reads)
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
      | set { ch_mtdnasnv_by_project }

    // Publish the single VCF
    ch_mtdnasnv_by_project.single
      | map { meta, vcf -> [meta, vcf.data, vcf.index, vcf.stats] }
      | publish_vcf
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_mtdnasnv_by_project_single }
    

    // Merge the multiple vcf files per project
    ch_mtdnasnv_by_project.multiple
      | map { meta, vcfs -> [meta, vcfs.collect { it.data }, vcfs.collect { it.index }] }
      | merge_mtdnasnv_vcf
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_mtdnasnv_by_project_merged }

    // Mix the output
    Channel.empty().mix(ch_mtdnasnv_by_project_merged, ch_mtdnasnv_by_project_single, ch_mtdnasnv_by_project.zero)
      | set { ch_mtdna_snv_processed }

    emit:
      ch_mtdna_snv_processed
}