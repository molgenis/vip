nextflow.enable.dsl=2

params.work = "."
params.in = "./ont_sample_data/small_X5_pod5"
params.out = "./vip_test_nf"

dorado_tool = "$params.work/dorado-0.3.4-linux-x64/bin/dorado"
dorado_model = "$params.work/dorado_models/dna_r10.4.1_e8.2_400bps_hac@v4.1.0/"
reference_g1k_v37 = "./ont_sample_data/human_g1k_v37.fasta"

process dorado {
	label 'dorado'
	publishDir './vip_test_nf/'

	input:
	path in
  
  	shell:
  """
  $dorado_tool basecaller $dorado_model $in --modified-bases 5mCG_5hmCG --reference $reference_g1k_v37 > small_X5.bam
  """

}  



workflow {
  Channel.of(params.in) | dorado
  samtools 
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