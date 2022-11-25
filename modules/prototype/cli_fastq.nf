include { validateCommonParams } from './cli'
include { parseCommonSampleSheet } from './sample_sheet'

def validateParams() {
  validateCommonParams()
  validateInput()
  validateReferenceMmi()
}

def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".tsv") ) exit 1, "parameter 'input' value '${params.input}' is not a .tsv file"
}

def validateReferenceMmi() {
  def assembly = params[params.assembly]
  def referenceMmi = assembly.reference.fastaMmi
  if( !file(referenceMmi).exists() )   exit 1, "parameter '${assembly}.reference.fastaMmi' value '${referenceMmi}' does not exist"
}

def parseSampleSheet(csvFile) {
  def cols = [
    seq_method: [
      type: "string",
      enum: ["WES","WGS"],
      required: true
    ],
    fastq_r1: [
      type: "file",
      required: true
    ],
    fastq_r2: [
      type: "file",
      required: true
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}

def countFamilySamples(sample, sampleSheet) {
    sampleSheet.count { thisSample -> sample.family_id == thisSample.family_id }
}