nextflow.enable.dsl=2

include { nrMappedReads } from '../modules/cram/utils'
include { expansionhunter_call } from '../modules/cram/expansionhunter'
include { merge_str_vcf } from '../modules/cram/merge_vcf'
include { straglr_call } from '../modules/cram/straglr'

/*
 * Variant calling: short tandem repeats
 *
 * input:  meta[project, sample, ...]
 * output: meta[project, ...        ], vcf
 */
workflow str {
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
      | set { ch_str }

    // split channel in crams based on tool that supports sequencing platform
    ch_str.with_reads
      | branch { meta ->
          expansionhunter: meta.project.sequencing_platform == 'illumina'
                           return meta
          stragler: params.str.straglr[meta.project.assembly] != null && (meta.project.sequencing_platform == 'nanopore' || meta.project.sequencing_platform == 'pacbio_hifi')
                           return meta
          ignore:          true
                           return [meta, null]
        }
      | set { ch_str_by_platform }

    // short tandem repeat detection with ExpansionHunter
    ch_str_by_platform.expansionhunter
      | map { meta -> [meta, meta.sample.cram.data, meta.sample.cram.index] }
      | expansionhunter_call
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_str_expansionhunter }

    // short tandem repeat detection with Stragler
    ch_str_by_platform.stragler
      | map { meta -> [meta, meta.sample.cram.data, meta.sample.cram.index] }
      | straglr_call
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_str_stragler }

    // group by project
    Channel.empty().mix(ch_str_expansionhunter, ch_str_stragler, ch_str.zero_reads, ch_str_by_platform.ignore)
      | map { meta, vcf -> [groupKey([*:meta].findAll { it.key != 'sample' }, meta.project.samples.size), [index: meta.sample.index, vcf: vcf]] }
      | groupTuple
      | map { key, group -> [key.getGroupTarget(), group.sort { left, right -> left.index <=> right.index }.collect { it.vcf }] }
      | branch { meta, vcfs ->
          multiple: vcfs.count { it != null } > 1
                    return [meta, vcfs.findAll { it != null }]
          single:   vcfs.count { it != null } == 1
                    return [meta, vcfs.find { it != null }]
          zero:     true
                    return [meta, null]
        }
      | set { ch_str_by_project }

    // merge: multiple vcfs
    ch_str_by_project.multiple
      | map { meta, vcfs -> [meta, vcfs.collect { it.data }, vcfs.collect { it.index }] }
      | merge_str_vcf
      | map { meta, vcf, vcfIndex, vcfStats -> [meta, [data: vcf, index: vcfIndex, stats: vcfStats]] }
      | set { ch_str_project_multiple }

    Channel.of().mix(ch_str_project_multiple, ch_str_by_project.single, ch_str_by_project.zero)
      | set { ch_str_processed }
    
  emit:
    ch_str_processed
}

def validateCallStrParams(assemblies) {
  // expansion hunter
  def expansionhunterAligner = params.str.expansionhunter.aligner
  if (!(expansionhunterAligner ==~ /dag-aligner|path-aligner/))  exit 1, "parameter 'cram.str.expansionhunter.aligner' value '${expansionhunterAligner}' is invalid. allowed values are [dag-aligner, path-aligner]"

  def expansionhunterAnalysisMode = params.str.expansionhunter.analysis_mode
  if (!(expansionhunterAnalysisMode ==~ /seeking|streaming/))  exit 1, "parameter 'cram.str.expansionhunter.analysis_mode' value '${expansionhunterAnalysisMode}' is invalid. allowed values are [seeking, streaming]"

  def expansionhunterLogLevel = params.str.expansionhunter.log_level
  if (!(expansionhunterLogLevel ==~ /trace|debug|info|warn|error/))  exit 1, "parameter 'cram.str.expansionhunter.log_level' value '${expansionhunterLogLevel}' is invalid. allowed values are [trace, debug, info, warn, error]"

  assemblies.each { assembly ->
    def expansionhunterVariantCatalog = params.str.expansionhunter[assembly].variant_catalog
    if(!file(expansionhunterVariantCatalog).exists() )   exit 1, "parameter 'cram.str.expansionhunter.${assembly}.variant_catalog' value '${expansionhunterVariantCatalog}' does not exist"
  }

  //stragler
  assemblies.each { assembly ->
    if(params.str.straglr[assembly] != null){
      def straglrLoci = params.str.straglr[assembly].loci
      if(!file(straglrLoci).exists() )   exit 1, "parameter 'params.str.straglr.${assembly}.loci' value '${straglrLoci}' does not exist"
    }
  }
}