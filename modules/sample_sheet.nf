def parseCommonSampleSheet(csvFilename, additionalCols) {
  def csvFile = new File(csvFilename)

  def seq_nr = 0
  
  def commonCols = [
    project_id: [
      type: "string",
      default: { 'vip' },
      regex: /[a-zA-Z0-9_-]+/
    ],
    family_id: [
      type: "string",
      default: { "vip_fam${seq_nr++}" },
      regex: /[a-zA-Z0-9_-]+/
    ],
    individual_id: [
      type: "string",
      required: true,
      regex: /[a-zA-Z0-9_-]+/
    ],
    paternal_id: [
      type: "string",
      regex: /[a-zA-Z0-9_-]+/
    ],
    maternal_id: [
      type: "string",
      regex: /[a-zA-Z0-9_-]+/
    ],
    sex: [
      type: "string",
      enum: ["male", "female"]
    ],
    affected: [
      type: "boolean",
    ],
    proband: [
      type: "boolean",
    ],
    hpo_ids: [
      type: "string",
      list: true,
      regex: /HP:\d{7}/
    ],
    assembly: [
      type: "string",
      default: { 'GRCh38' },
      enum: ['GRCh37', 'GRCh38']
    ],
    sequencing_method: [
      type: "string",
      default: { 'WGS' },
      enum: ['WES', 'WGS']
    ]
  ]

  def cols = [*:commonCols, *:additionalCols]
    
  def lines = csvFile.readLines("UTF-8")
  if (lines.size() == 0) exit 1, "error parsing '${csvFilename}': file is empty"
  
  def headerTokens = lines[0].split('\t', -1)
  def colsWithIndex
  try {
    colsWithIndex = parseHeader(headerTokens, cols)
  } catch(IllegalArgumentException e) {
    exit 1, "error parsing '${csvFilename}' line 1: ${e.message}"
  }
  
  if (lines.size() == 1) exit 1, "error parsing '${csvFilename}': file does not contain data"

  def samples=[]
  for (int i = 1; i < lines.size(); i++) {
    def lineNr = i + 1

    def line = lines[i]
    if (line == null) continue;
    
    def tokens = line.split('\t', -1)
    if (tokens.length != headerTokens.length) exit 1, "error parsing '${csvFilename}' line ${lineNr}: expected ${headerTokens.length} columns instead of ${tokens.length}"
    
    def sample
    try {
      sample = parseSample(tokens, colsWithIndex, csvFile.getParentFile())
    } catch(IllegalArgumentException e) {
      exit 1, "error parsing '${csvFilename}' line ${lineNr}: ${e.message}"
    }
    sample.index = i
    samples << sample
  }

  validate(samples);
  
  return samples
}

def validate(samples){
  def sampleMap = [:]
  samples.each{ sample ->
    if(sampleMap[[id: sample.individual_id, projectId: sample.project_id]] != null)  exit 1, "Individual_id '${sample.individual_id}' already exists in project '${sample.project_id}', individual_id should be unique within a project."
    sampleMap[[id: sample.individual_id, projectId: sample.project_id]] = [projectId : sample.project_id, familyId : sample.family_id]
  }
  samples.each{ sample ->
    if(sample.paternal_id != null){
      if(sampleMap[[id: sample.paternal_id, projectId: sample.project_id]] == null) exit 1, "Paternal_id sample '${sample.paternal_id}' for sample '${sample.individual_id}' is not present in project '${sample.project_id}'."
      if(sampleMap[[id: sample.paternal_id, projectId: sample.project_id]].familyId != sample.family_id) exit 1, "Paternal_id sample '${sample.paternal_id}' for sample '${sample.individual_id}' belongs to a different family."
    }
    if(sample.maternal_id != null){
      if(sampleMap[[id: sample.maternal_id, projectId: sample.project_id]] == null) exit 1, "Maternal_id sample '${sample.maternal_id}' for sample '${sample.individual_id}' is not present in project '${sample.project_id}'."
      if(sampleMap[[id: sample.maternal_id, projectId: sample.project_id]].familyId != sample.family_id) exit 1, "Maternal_id sample '${sample.maternal_id}' for sample '${sample.individual_id}' belongs to a different family."
    }
  }
}

def parseHeader(tokens, colMetaMap) {
  def colIndexMap = [:]
  tokens.eachWithIndex { token, index ->
    if (!colMetaMap.containsKey(token) ) {
      throw new IllegalArgumentException("unknown column '${token}'")
    }
    colIndexMap[token] = index
  }

  def colMetaIndexMap=[:]
  colMetaMap.each { colId, col ->
    def index = colIndexMap.get(colId)
    if (index == null) {
      if(col.required == true) throw new IllegalArgumentException("missing column '${colId}'")
    }
    colMetaIndexMap[colId] = [*:col, index: index]
  }

  return colMetaIndexMap
}

def parseValueStringList(token, col) {
  def values = token.length() > 0 ? token.split(',', -1) : []
  if(col.required && values.size() == 0) throw new IllegalArgumentException("required value is empty")
  return values.collect(value -> parseValueString(value, col))
}

def parseValueString(token, col) {
  def value = token.length() > 0 ? token : (col.default ? col.default() : null)
  if(col.required && value == null) throw new IllegalArgumentException("required value is empty")
  if(value != null) {
    if(col.enum && !col.enum.contains(value) && value != null) throw new IllegalArgumentException("invalid value '${token}', valid values are [${col.enum.join(", ")}]")
    if(col.regex && !(value ==~ col.regex)) throw new IllegalArgumentException("invalid value '${token}' does not match regex '${col.regex}'")
  }
  return value
}

def parseValueBoolean(token, col) {
  def value = token.length() > 0 ? token : (col.default ? col.default() : null)
  if(col.required && value == null) throw new IllegalArgumentException("required value is empty")
  
  def booleanValue
  if(value == null) booleanValue = null
  else if(value == "true") booleanValue = true
  else if(value == "false") booleanValue = false
  else throw new IllegalArgumentException("invalid value '${token}', valid values are [true, false]")
  return booleanValue
}

def parseValueFileList(token, col, rootDir) {
  def values = token.length() > 0 ? token.split(',', -1) : []
  if(col.required && values.size() == 0) throw new IllegalArgumentException("required value is empty")
  return values.collect(value -> parseValueFile(value, col, rootDir))
}

def parseValueFile(token, col, rootDir) {
  def value = token.length() > 0 ? token : (col.default ? col.default() : null)
  if(col.required && value == null) throw new IllegalArgumentException("required value is empty")
  def fileValue
  if(value != null) {
    def relative = value.startsWith('/')
    fileValue = relative ? file(value) : file(new File(value, rootDir).getPath())
    if(!fileValue.exists()) throw new IllegalArgumentException(relative ? "file '${token}' in directory '${rootDir}' does not exist" : "file '${token}' does not exist")
    if(!fileValue.isFile()) throw new IllegalArgumentException("file '${token}' is not a file")
    if(col.regex && !(value ==~ col.regex)) throw new IllegalArgumentException("invalid value '${token}' does not match regex '${col.regex}'")
  }
  return fileValue
}

def parseValue(token, col, rootDir) {
  def value
  switch(col.type) {
    case "string":
      value = col.list ? parseValueStringList(token, col) : parseValueString(token, col)
      break
    case "boolean":
      value = parseValueBoolean(token, col)
      break
    case "file":
      value = col.list ? parseValueFileList(token, col, rootDir) : parseValueFile(token, col, rootDir)
      break
    default:
      throw new RuntimeException("unexpected column type '${col.type}'")
  }
  return value;
}

def parseSample(tokens, cols, rootDir) {
    def sample = [:]
    cols.each { colId, col -> 
      def token = col.index != null ? tokens[col.index] : ''
      try {
        sample[colId] = parseValue(token, col, rootDir)
      } catch(IllegalArgumentException e) {
        throw new IllegalArgumentException("column '${colId}': ${e.message}")
      }
    }
    return sample
}

def getAssemblies(sampleSheet) {
  sampleSheet.collect(sample -> sample.assembly).unique()
}