nextflow.enable.dsl=2

include { scatter } from '../modules/prototype/utils'
include { bcftools_concat; bcftools_index; bcftools_view_chunk_vcf } from '../modules/prototype/bcftools'
include { vcf_report } from '../modules/prototype/vcf_report'

//TODO add vip
workflow vip_vcf {
    take: meta
    main:
        meta
            | collect(sort: { metaLeft, metaRight -> metaRight.chunk.index <=> metaLeft.chunk.index })
            | map { metaList -> tuple([], metaList.collect { meta -> meta.vcf }) }
            | bcftools_concat
            | map { meta, vcf, vcfCsi -> [*:meta, vcf: vcf, vcf_index: vcfCsi]}
            | map { meta -> tuple(meta, meta.vcf, meta.vcf_index, params.reference, params.reference + ".fai", params.reference + ".gzi") }
            | vcf_report
}

// FIXME cli
// TODO parameter validation
// TODO make indexing optional if index exists
workflow {    
    // split .vcf before calling subworkflow
    Channel.from([vcf: params.vcf])
        | flatMap { meta -> scatter(meta) }
        | map { meta -> tuple(meta, meta.vcf) }
        | bcftools_index
        | map { meta, vcfIndex -> [*:meta, vcf_index: vcfIndex] }
        | map { meta -> tuple(meta, meta.vcf, meta.vcf_index) }
        | bcftools_view_chunk_vcf
        | map { meta, vcfChunk, vcfChunkIndex -> [*:meta, vcf: vcfChunk, vcf_index: vcfChunkIndex] }
        | vip_vcf
}
