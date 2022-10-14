nextflow.enable.dsl=2

include { samtools_idxstats; parseAlignmentStats } from '../modules/prototype/samtools'
include { deepvariant_call; deeptrio_call; deeptrio_call_duo_father; deeptrio_call_duo_mother } from '../modules/prototype/deepvariant'
include { vip_gvcf } from './vip_gvcf'
include { validateMeta } from '../modules/prototype/utils'

def countFamilySamples(sample, sampleSheet) {
    sampleSheet.count { thisSample -> sample.family_id == thisSample.family_id }
}

workflow vip_cram {
    take: meta
    main:
        meta
            | map { meta -> validateMeta(meta, ["sample", "sampleSheet", "reference"]) }
            | map { meta -> tuple(groupKey(meta.sample.family_id, countFamilySamples(meta.sample, meta.sampleSheet)), meta) }
            | groupTuple
            | flatMap { key, group -> group.collect { [*:it, family: group.collectEntries{ meta -> [meta.sample.individual_id, meta] }] } }
            | filter { meta -> meta.sample.proband }
            | map { meta -> tuple(meta, meta.cram, meta.cram_index) }
            | samtools_idxstats
            | flatMap { meta, statsFile ->
                def stats = parseAlignmentStats(statsFile)
                def contigsWithReads = contigs.findAll { (it == "chr21" || it == "chr22") && (stats[it].nrMappedReads + stats[it].nrUnmappedReads > 0) }
                contigsWithReads.collect { contig -> [*:meta, contig: contig, nr_contigs: contigsWithReads.size()] }
            }
            | branch { meta ->
                trio: meta.sample.paternal_id != null && meta.sample.maternal_id != null
                duoFather: meta.sample.paternal_id != null && meta.sample.maternal_id == null
                duoMother: meta.sample.paternal_id == null && meta.sample.maternal_id != null
                single: true
            }
            | set { variant_call_branch_ch } 
        
        variant_call_branch_ch.trio
            | map { meta -> tuple(meta, reference, referenceFai, referenceGzi,
                meta.cram, meta.cram_index,
                meta.family[meta.sample.paternal_id].cram, meta.family[meta.sample.paternal_id].cram_index,
                meta.family[meta.sample.maternal_id].cram, meta.family[meta.sample.maternal_id].cram_index)
            }
            | deeptrio_call
            | flatMap { meta, gVcf, gVcfFather, gVcfMother -> [[*:meta, gVcf: gVcf], [*:meta.family[meta.sample.paternal_id], gVcf: gVcfFather, contig: meta.contig, nr_contigs: meta.nr_contigs], [*:meta.family[meta.sample.maternal_id], gVcf: gVcfMother, contig: meta.contig, nr_contigs: meta.nr_contigs]] }
            | set { variant_call_trio_processed_ch }

        variant_call_branch_ch.duoFather
            | map { meta -> tuple(meta,
                reference, referenceFai, referenceGzi,
                meta.cram, meta.cram_index,
                meta.family[meta.sample.paternal_id].cram, meta.family[meta.sample.paternal_id].cram_index)
            }
            | deeptrio_call_duo_father
            | flatMap { meta, gVcf, gVcfFather -> [[*:meta, gVcf: gVcf], [*:meta.family[meta.sample.paternal_id], gVcf: gVcfFather, contig: meta.contig, nr_contigs: meta.nr_contigs]] }
            | set { variant_call_duoFather_processed_ch }

        variant_call_branch_ch.duoMother
            | map { meta -> tuple(meta,
                reference, referenceFai, referenceGzi,
                meta.cram, meta.cram_index,
                meta.family[meta.sample.maternal_id].cram, meta.family[meta.sample.maternal_id].cram_index)
            }
            | deeptrio_call_duo_mother
            | flatMap { meta, gVcf, gVcfMother -> [[*:meta, gVcf: gVcf], [*:meta.family[meta.sample.maternal_id], gVcf: gVcfMother, contig: meta.contig, nr_contigs: meta.nr_contigs]] }
            | set { variant_call_duoMother_processed_ch }

        variant_call_branch_ch.single \
            | map { meta -> tuple(meta,
                reference, referenceFai, referenceGzi,
                meta.cram, meta.cram_index)
            }
            | deepvariant_call
            | map { meta, gVcf -> [ *:meta, gVcf: gVcf ] }
            | set { variant_call_other_processed_ch }

        variant_called_ch = variant_call_other_processed_ch.mix(
            variant_call_trio_processed_ch,
            variant_call_duoFather_processed_ch,
            variant_call_duoMother_processed_ch
            )

        variant_called_ch
            | vip_gvcf
}

// FIXME implement CLI
workflow {
    vip_cram()
}