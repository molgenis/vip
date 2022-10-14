nextflow.enable.dsl=2

include { glnexus_merge } from '../modules/prototype/glnexus'
include { bcftools_concat } from '../modules/prototype/bcftools'
include { vip_vcf } from './vip_vcf'

workflow vip_gvcf {
    take: meta
    main:
        meta
            | map { meta -> tuple(groupKey(meta.contig, nrSamples), meta) }
            | groupTuple
            | map { key, group -> tuple([contig: key, samples: group], group.collect(meta -> meta.gVcf)) }
            | glnexus_merge
            | map { meta, bcf -> [*:meta, bcf: bcf] }
            | set { bcf_region_ch }

        bcf_region_ch 
            | toSortedList { thisMeta, thatMeta -> contigs.findIndexOf{ it == thatMeta.contig } <=> contigs.findIndexOf{ it == thisMeta.contig } }
            | map { metaList -> tuple(metaList, metaList.collect{ meta -> meta.bcf }) }
            | bcftools_concat
            | map { metaList, vcf -> [vcf: vcf, reference: [fasta: reference, fai: referenceFai, gzi: referenceGzi]] }
            | vip_vcf
}

// FIXME implement CLI
workflow {
    vip_gvcf()
}