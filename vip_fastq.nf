nextflow.enable.dsl=2

include { validateParams; parseSampleSheet } from './modules/prototype/cli_fastq'
include { minimap2_align } from './modules/prototype/minimap2'
include { vip_cram } from './vip_cram'

process concat_fastq {
  input:
    tuple val(meta), path(fastq_r1s), path(fastq_r2s)
  output:
    tuple val(meta), path(fastq_r1), path(fastq_r2)
  script:
    sample_id="${meta.sample.family_id}_${meta.sample.individual_id}"
    fastq_r1="${sample_id}_r1.fastq.gz"
    fastq_r2="${sample_id}_r2.fastq.gz"
    """
    cat ${fastq_r1s} > ${fastq_r1}
    cat ${fastq_r2s} > ${fastq_r2}
    """
}

//TODO instead of concat_fastq, align in parallel and merge bams (keep in mind read groups when marking duplicates)
workflow vip_fastq {
    take: meta
    main:
        meta
            | branch { meta ->
                merge: meta.sample.fastq_r1.size() > 1 || meta.sample.fastq_r2.size() > 1
                ready: true
              }
            | set { ch_input }
        
        ch_input.merge
            | map { meta -> tuple(meta, meta.sample.fastq_r1, meta.sample.fastq_r2) }
            | concat_fastq
            | map { meta, fastq_r1, fastq_r2 -> [*:meta, sample: [*:meta.sample, fastq_r1: fastq_r1, fastq_r2: fastq_r2] ] }
            | set { ch_input_merged }

        ch_input_merged.mix(ch_input.ready)
            | map { meta -> tuple(meta, meta.sample.fastq_r1, meta.sample.fastq_r2) }
            | minimap2_align
            | map { meta, cram, cramIndex -> [*:meta, sample: [*:meta.sample, cram: cram, cram_index: cramIndex] ] }
            | vip_cram
}

//TODO make .mmi optional
workflow {
    validateParams()

    def sampleSheet = parseSampleSheet(params.input)

    Channel.from(sampleSheet)
    | map { sample -> [sample: sample]}
    | vip_fastq
}