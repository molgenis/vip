nextflow.enable.dsl=2

// Modules to include
include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'
include { dorado } from './modules/mod/dorado'
include { sort_bam } from './modules/mod/samtools'
include { modkit } from './modules/mod/modkit'
include { methplotlib } from './modules/mod/methplotlib'

workflow mod{
	// Base modification workflow 

    take: meta
    main:
	  meta
		| branch { meta ->
			pod5_data: !meta.sample.pod5.isEmpty()
			ready: true
		}
		| set { ch_input }

	// Basecalling using Dorado
	
	ch_input.pod5_data
	| map { meta -> [meta, meta.sample.pod5] }
	| dorado
	| set {ch_input_basecalled}

	// Sorting output bam files from Dorado

	ch_input_basecalled
	| map { meta, bam -> [ meta, bam ]}
	| sort_bam
	| set {ch_basecalled_sorted}

	// Processing bam files by modkit

	ch_basecalled_sorted
	| map { meta, sorted_bam, sorted_bam_index -> [ meta, sorted_bam, sorted_bam_index ]}
	| modkit
	| set { ch_input_bedmethyl }

	// View output hashmap

	ch_input_bedmethyl
	| map { meta, bed, region -> [ meta, bed, meta.sample.region ]}
	| methplotlib
	| set { ch_input_methylfreq }
	
}

workflow {
	// Main workflow

	def projects = parseSampleSheet(params.input)
	def assemblies = getAssemblies(projects)

	// Eventueel een validate mod params

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
		type: "string",
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
