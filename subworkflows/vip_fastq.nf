nextflow.enable.dsl=2

include { parseSampleSheet } from '../modules/prototype/sample_sheet'
include { minimap2_align } from '../modules/prototype/minimap2'
include { samtools_idxstats; parseFastaIndex } from '../modules/prototype/samtools'
include { bcftools_view_contig } from '../modules/prototype/bcftools'
include { validateParams } from '../modules/prototype/cli'
include { vip_cram } from './vip_cram'
include { validateMeta } from '../modules/prototype/utils'

workflow vip_fastq {
    take: meta
    main:
        meta
            | map { meta -> validateMeta(meta, ["sample", "sampleSheet", "reference"]) }
            | map { meta -> tuple(meta, meta.reference.fasta, meta.reference.fai, meta.reference.gzi, meta.reference.mmi) }
            | minimap2_align
            | map { meta, cram, cramIndex -> [*:meta, sample: [*:meta.sample, cram: cram, cram_index: cramIndex] ] }
            | vip_cram
}

workflow {
    validateParams()

    def input = params.input

    def fasta = params.reference
    def fai = params.reference + ".fai"
    def gzi = params.reference + ".gzi" 
    def mmi = params.reference + ".mmi"

    def sampleSheet = parseSampleSheet(input)
    
    def reference = [
        fasta: fasta,
        fai: fai,
        gzi: gzi,
        mmi: mmi,
        contigs: parseFastaIndex(fai)
    ]

    sample_ch = Channel.from(sampleSheet) \
    | map { sample -> [sample: sample, sampleSheet: sampleSheet, reference: reference]}
    | vip_fastq
}