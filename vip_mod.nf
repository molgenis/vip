nextflow.enable.dsl=2

// Modules to include
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { validateGroup } from './modules/utils'
include { dorado } from './modules/mod/dorado'
include { sort_bam } from './modules/mod/samtools'
include { modkit } from './modules/mod/modkit'
include { cram; validateCramParams } from './vip_cram'

workflow mod {
	// Base modification workflow 
    take: meta
    main:
	  meta
		| branch { meta ->
			pod5_data: !meta.sample.pod5.isEmpty()
			ready: true
		}
		| set { ch_input }
	
	ch_input.pod5_data
	| map { meta -> [*:meta, sample:[*:meta.sample, pod5:meta.sample.pod5] ] }
	| set {ch_input_ready}

	// Basecalling using Dorado
	ch_input_ready
	| map { meta -> [ meta, meta.sample.pod5]}
	| dorado
	| map { meta, bam -> [*:meta, sample: [*:meta.sample, bam: bam]] }
	| set {ch_basecalled}

	// Sorting output bam files from Dorado

	ch_basecalled
	| map { meta -> [ meta, meta.sample.bam ] }
	| sort_bam
	| map { meta, sortedBam, sortedBamIndex, sortedBamStats -> [*:meta, sample: [*:meta.sample, cram: sortedBam, cramIndex: sortedBamIndex, cramStats: sortedBamStats]] }
	| set {ch_basecalled_sorted}

	// Processing bam files by modkit

	ch_basecalled_sorted
	| map { meta -> [ meta, meta.sample.cram, meta.sample.cramIndex ]}
	| modkit
	| map { meta, bedmethyl -> [ *:meta, sample: [*:meta.sample, bedmethyl: bedmethyl]]}
	| cram
	
}

workflow {
	// Main workflow
	def projects = parseSampleSheet(params.input)
	Channel.from(projects)
		| flatMap { project -> project.samples.collect { sample -> [project: project, sample: sample] } }
    	| mod
}

def parseSampleSheet(csvFile){
	// Parse sample sheet: check for pod5 files

	def pod5Regex = /.+\.(pod5)(\.gz)?/

    def cols = [
    pod5: [
      type: "file",
	  list: true,
	  required: true,
	  regex: pod5Regex
    ],
	region: [
		type: "string"
	],
    sequencing_platform: [
      type: "string",
      default: { 'nanopore' },
      enum: ['illumina', 'nanopore', 'pacbio_hifi'],
      scope: "project"
    ]
  ]

	return parseCommonSampleSheet(csvFile, cols)
}

