include { validateCommonParams } from './cli'
include { parseCommonSampleSheet } from './sample_sheet'

def validateParams() {
  validateCommonParams()
  validateInput()
}

def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".tsv") ) exit 1, "parameter 'input' value '${params.input}' is not a .tsv file"
}

def parseSampleSheet(csvFile) {
  def cols = [
    seq_method: [
      type: "string",
      enum: ["WES","WGS"],
      required: true
    ],
    cram: [
      type: "file",
      required: true
    ],
    cram_index: [
      type: "file"
    ]
  ]
  return parseCommonSampleSheet(csvFile, cols)
}
