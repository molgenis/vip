nextflow.enable.dsl=2

include { dorado } from './modules/mod/dorado'
include { sort_bam } from './modules/mod/samtools'
include { modkit } from './modules/mod/modkit'

workflow {
  	dorado_mod_bam = Channel.of(params.pod5) | dorado
	sorted_bam = sort_bam(dorado_mod_bam)
	modkit(sorted_bam)
}





 /*Below is the first draft of the vip pipeline with template as vip. 
 Needs revision and more detailed.
 
 */
// include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'


// // workflow mod {
// //     take: meta
// //     main: 
// //         //do something

// // }

// workflow {
//     def projects = parseSampleSheet(params.input)
//     // def assemblies = getAssemblies(projects)
//     // validateModParams(assemblies)
// }

// def validateModParams(assemblies){
//     // validate next input params

// }

// def parseSampleSheet(csvFile){
//     def cols = [
//     pod5: [
//       type: "path",
//       required: true
// 	  // In samplesheet.nf fix that path is accepted
//     ],
//     sequencing_platform: [
//       type: "string",
//       default: { 'nanopore' },
//       enum: ['illumina', 'nanopore', 'pacbio_hifi'],
//       scope: "project"
//     ]
//   ]

// //   return parseCommonSampleSheet(csvFile, cols)
// }