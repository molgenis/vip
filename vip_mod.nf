nextflow.enable.dsl=2

include { parseCommonSampleSheet; getAssemblies } from './modules/sample_sheet'


// workflow mod {
//     take: meta
//     main: 
//         //do something

// }

workflow {
    def projects = parseSampleSheet(params.input)
    // def assemblies = getAssemblies(projects)
    // validateModParams(assemblies)
}

def validateModParams(assemblies){
    // validate next input params

}

def parseSampleSheet(csvFile){
    def cols = [
    pod5: [
      type: "path",
      required: true
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