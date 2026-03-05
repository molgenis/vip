nextflow.enable.dsl=2

include { scatter; validateGroup } from '../modules/utils'
include { nrMappedReadsInChunk } from '../modules/cram/utils'
include { deepvariant; validateCallDeepVariantParams } from '../subworkflows/call_snv_deepvariant'
include { mtdnasnv } from '../subworkflows/call_mtdna_snv'
include { split_cram_chrm } from '../modules/cram/split_cram_chrm'
include { concat_snv_vcf } from '../modules/cram/concat_snv_vcf'
/*
 * Variant calling: single nucleotide variants and short insertions/deletions
 *
 * input:  meta[project, sample, ...]
 * output: meta[project, ...        ], vcf
 */
workflow snv {
  take: meta
  main:
    meta
      | map { meta -> [meta, meta.sample.cram.data, meta.sample.cram.index] }
			| split_cram_chrm
			| map { meta, chrmCram, chrmCramIndex, chrmCramStats, nonchrmCram, nonchrmCramIndex, nonchrmCramStats
				-> 
				[*:meta, sample: [*:meta.sample, cram: [data: nonchrmCram, index: nonchrmCramIndex, stats: nonchrmCramStats, chrmdata: chrmCram, chrmindex: chrmCramIndex, chrmstats: chrmCramStats]]]
				}
			| multiMap { it -> normal: chrm: it }
			| set { ch_snv }
    
    ch_snv.chrm
      | mtdnasnv
      | set { ch_snv_mtdna }

    // add family to each sample
    ch_snv.normal
      | map { meta ->
          def familySize = meta.project.samples.count { it.family_id == meta.sample.family_id }
          def family = [id: meta.sample.family_id]
          return [groupKey([*:meta, family: family].findAll { it.key != 'sample' }, familySize), meta.sample]
        }
      | groupTuple(remainder: true, sort: { left, right -> left.index <=> right.index })
      | map { key, group -> validateGroup(key, group) }
      | map { meta, samples -> [*:meta, family: [*:meta.family, samples: samples]] }
      | flatMap { meta -> meta.family.samples.collect { sample -> [*:meta, sample: sample ] } }
      | set { ch_snv_family }
      
    // split channel in cram chunks with and without mapped reads
    ch_snv_family
      | flatMap { meta -> scatter(meta) }
      | set { ch_snv_family_chunk }

    // split channel in crams based on tool that supports sequencing platform
    ch_snv_family_chunk
      | branch { meta ->
          deepvariant: meta.project.sequencing_platform == 'illumina' || meta.project.sequencing_platform == 'nanopore' || meta.project.sequencing_platform == 'pacbio_hifi'
          // add new tools here
        }
      | set { ch_snv_chunk_by_platform }

    ch_snv_chunk_by_platform.deepvariant
      | deepvariant
      | set { ch_snv_deepvariant }
    
    // Concat the vcfs of both deepvariant and gatk
    Channel.empty().mix(ch_snv_deepvariant, ch_snv_mtdna)
      | map { meta, vcf -> [groupKey(meta, 2), vcf] }
      | groupTuple(remainder: true)
      | map { key, group -> validateGroup(key, group) }
      | branch { meta, vcfs ->
        multiple: vcfs.count { it != null } > 1
                  return [meta, vcfs.findAll { it != null } ]
        single:   vcfs.count { it != null } == 1
                  return [meta, vcfs.find { it != null } ]
        zero:     true
                  return [meta, null]
        }
      | set { ch_snv_called }

    ch_snv_called.multiple
      | map { meta, vcfs -> [meta, vcfs.collect { it.data }, vcfs.collect { it.index }] }
      | concat_snv_vcf
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_snv_called_multiple }
    
    Channel.empty().mix(ch_snv_called_multiple, ch_snv_called.single)
      | set { ch_snv_processed }

    // mix outputs of all tools
    //Channel.empty().mix(ch_snv_deepvariant, ch_snv_mtdna)
    //  | view
    //  | set { ch_snv_processed }
  emit:
    ch_snv_processed
}

def validateCallSnvParams(assemblies) {
  validateCallDeepVariantParams(assemblies)
}