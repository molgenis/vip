nextflow.enable.dsl=2

include { parseSampleSheet } from './modules/prototype/sample_sheet'
include { minimap2_align } from './modules/prototype/minimap2'
include { samtools_idxstats; parseAlignmentStats; parseFastaIndex } from './modules/prototype/samtools'
include { deepvariant_call; deeptrio_call; deeptrio_call_duo_father; deeptrio_call_duo_mother } from './modules/prototype/deepvariant'
include { glnexus_merge } from './modules/prototype/glnexus'
include { bcftools_concat; bcftools_concat_index; bcftools_view_contig } from './modules/prototype/bcftools'
include { vcf_report_create } from './modules/prototype/vcf_report'
include { validate } from './modules/prototype/cli'

workflow {
  validate()

  def referenceFai = params.reference + ".fai"
  def referenceGzi = params.reference + ".gzi"
  def referenceMmi = params.reference + ".mmi"

  def sampleSheet = parseSampleSheet(params.input)
  // FIXME calculate from sample sheet
  def nrSamples = 9
  def contigs = parseFastaIndex(referenceFai)
 
  sample_ch = Channel.from(sampleSheet.entrySet()) \
    | flatMap { it.value.values() }

  // FIXME doesn't work when some duo/trio samples have gVCF while others have not
  sample_ch \
    | branch {
        gVcf: it.g_vcf != null
        cram: it.g_vcf == null && it.cram != null
        fastq: true
      }
    | set { sample_branch_ch }

  sample_branch_ch.fastq \
    | map { tuple(it, params.reference, referenceFai, referenceGzi, referenceMmi) }
    | minimap2_align
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.cram=tuple[1]
        sample.cram_index=tuple[2]
        sample
      }
    | set { sample_fastq_ch }

  sample_cram_ch = sample_branch_ch.cram.mix(sample_fastq_ch)

  sample_cram_ch \
    | map { sample -> tuple(groupKey(sample.family_id, sampleSheet[sample.family_id].size()), sample) }
    | groupTuple
    | map { group -> group[1] }
    | set { family_cram_ch }
  
  family_cram_ch
    | flatMap { samples ->
        def family = [:]
        samples.each { sample -> family[sample.individual_id] = sample }
        samples.collect { sample -> 
          def sampleWithFamily = sample.clone()
          sampleWithFamily.family = family
          sampleWithFamily
        }
      }
    | filter { sample -> sample.proband}
    | set { proband_cram_ch }
  
  proband_cram_ch
    | map { sample -> tuple(sample, sample.cram, sample.cram_index) }
    | samtools_idxstats
    | flatMap { sample, statsFile ->
        def stats = parseAlignmentStats(statsFile)
        // FIXME remove (contig == "chr21" || contig == "chr22")
        def contigsWithReads = contigs.findAll( contig -> { (contig == "chr21" || contig == "chr22") && (stats[contig].nrMappedReads + stats[contig].nrUnmappedReads > 0) } )
        contigsWithReads.collect{ contig -> 
          def samplePerContig = sample.clone()
          samplePerContig.contig = contig
          samplePerContig.nr_contigs = contigsWithReads.size()
          samplePerContig
        }
      }
    | set {proband_cram_region_ch }

  proband_cram_region_ch
    | branch { sample ->
        trio: sample.paternal_id != null && sample.maternal_id != null
        duoFather: sample.paternal_id != null && sample.maternal_id == null
        duoMother: sample.paternal_id == null && sample.maternal_id != null
        other: true
      }
    | set { proband_cram_region_branch_ch } 
  
  proband_cram_region_branch_ch.trio
    | map { sample -> 
        tuple(
          sample,
          params.reference, referenceFai, referenceGzi,
          sample.cram, sample.cram_index,
          sample.family[sample.paternal_id].cram, sample.family[sample.paternal_id].cram_index,
          sample.family[sample.maternal_id].cram, sample.family[sample.maternal_id].cram_index
        )
      }
    | deeptrio_call
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample.family=sample.family.clone()
        sample.family[sample.paternal_id].g_vcf=tuple[2]
        sample.family[sample.maternal_id].g_vcf=tuple[3]
        sample
      }
    | set { proband_gvcf_region_trio_ch }

  proband_cram_region_branch_ch.duoFather
    | map { sample -> 
        tuple(
          sample,
          params.reference, referenceFai, referenceGzi,
          sample.cram, sample.cram_index,
          sample.family[sample.paternal_id].cram, sample.family[sample.paternal_id].cram_index
        )
      }
    | deeptrio_call_duo_father
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample.family=sample.family.clone()
        sample.family[sample.paternal_id].g_vcf=tuple[2]
        sample
      }
    | set { proband_gvcf_region_duo_father_ch }

proband_cram_region_branch_ch.duoMother
    | map { sample -> 
        tuple(
          sample,
          params.reference, referenceFai, referenceGzi,
          sample.cram, sample.cram_index,
          sample.family[sample.maternal_id].cram, sample.family[sample.maternal_id].cram_index
        )
      }
    | deeptrio_call_duo_mother
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample.family=sample.family.clone()
        sample.family[sample.maternal_id].g_vcf=tuple[2]
        sample
      }
    | set { proband_gvcf_region_duo_mother_ch }

  proband_cram_region_branch_ch.other \
    | map { sample -> 
        tuple(
          sample,
          params.reference, referenceFai, referenceGzi,
          sample.cram, sample.cram_index
        )
      }
    | deepvariant_call
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample
      }
    | set { proband_gvcf_region_other_ch }

  proband_gvcf_region_ch = proband_gvcf_region_trio_ch.mix(proband_gvcf_region_other_ch, proband_gvcf_region_duo_father_ch, proband_gvcf_region_duo_mother_ch)

  // FIXME move father.contig etc. to proband_cram_ch 
  proband_gvcf_region_ch
    | flatMap { sample -> 
        def samples = []
        samples << sample
        
        def father = sample.family[sample.paternal_id]
        if(father) {
          father = father.clone()
          father.contig = sample.contig
          father.nr_contigs = sample.nr_contigs
          samples << father
        }
        
        def mother = sample.family[sample.maternal_id]
        if(mother) {
          mother = mother.clone()
          mother.contig = sample.contig
          mother.nr_contigs = sample.nr_contigs
          samples << mother
        }
        samples
      }
    | multiMap { done: publish: it }
    | set { sample_gvcf_region_ch }

  sample_gvcf_region_ch.publish
    | map { sample -> tuple(groupKey(sample.family_id + "_" + sample.individual_id, sample.nr_contigs), sample) }
    | groupTuple
    | map { group -> group[1] }
    | map { samples -> samples.sort { thisSamples, thatSamples -> contigs.findIndexOf{ it == thisSamples.contig } <=> contigs.findIndexOf{ it == thatSamples.contig } } }
    | map { samples -> tuple(samples[0], samples.collect(sample -> sample.g_vcf)) }
    | bcftools_concat_index

  // split gvcf from here
  sample_branch_ch.gVcf \
    | flatMap { sample ->
      contigs.collect { contig ->
        samplePerContig = sample.clone()
        samplePerContig.contig = contig
        // FIXME contigs.size() instead of 2
        samplePerContig.nr_contigs = 2
        samplePerContig
        // FIXME remove (contig == "chr21" || contig == "chr22")
      }.findAll { samplePerContig -> (samplePerContig.contig == "chr21" || samplePerContig.contig == "chr22") }
    }
    | map { sample -> tuple(sample, sample.g_vcf, sample.g_vcf_index) }
    | bcftools_view_contig
    | map { tuple ->
        def sample = tuple[0].clone()
        sample.g_vcf=tuple[1]
        sample.g_vcf_index=null
        sample
      }
    | set { sample_start_with_gvcf_region_ch }

  sample_gvcf_region_mix_ch=sample_gvcf_region_ch.done.mix(sample_start_with_gvcf_region_ch)
  
  sample_gvcf_region_mix_ch
    | map { sample -> tuple(groupKey(sample.contig, nrSamples), sample) }
    | groupTuple
    | map { group -> tuple([contig: group[0], samples: group[1]], group[1].collect(sample -> sample.g_vcf)) }
    | glnexus_merge
    | map { tuple ->
        def contigSamples = tuple[0].clone()
        contigSamples.bcf=tuple[1]
        contigSamples
      }
    | set { bcf_region_ch }

  // TODO nanopore
  // TODO mantasv
  // TODO report probands
  // TODO report pedigree
  // TODO report reference
  // TODO report crams
  // TODO report genes
  // TODO report phenotypes from sample sheet
  bcf_region_ch 
    | toSortedList { thisContigSamples, thatContigSamples -> 
        contigs.findIndexOf{ it == thatContigSamples.contig } <=> contigs.findIndexOf{ it == thisContigSamples.contig }
      }
    | map { contigSamples -> contigSamples.collect{ it.bcf } }
    | bcftools_concat
    | map { vcf -> tuple(vcf, params.reference, referenceFai, referenceGzi) }
    | vcf_report_create

  // TODO start from gvcf
  // TODO start from vcf
  // TODO publish result
  // TODO publish intermediate results
}
