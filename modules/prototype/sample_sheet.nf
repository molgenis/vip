def parseCommonSampleSheet(csvFile, additionalCols) {
  def commonCols = [
    family_id: [
      type: "string",
      required: true
    ],
    individual_id: [
      type: "string",
      required: true
    ],
    paternal_id: [
      type: "string",
    ],
    maternal_id: [
      type: "string",
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
    hpo_terms: [
      type: "string",
      list: true,
      regex: /HP:\d{7}/
    ],
  ]

  def cols = [*:commonCols, *:additionalCols]
    
  def lines = new File(csvFile).readLines("UTF-8")
  if (lines.size() == 0) exit 1, "error parsing '${csvFile}': file is empty"
  
  def headerTokens = lines[0].split('\t', -1)
  def colsWithIndex
  try {
    colsWithIndex = parseHeader(headerTokens, cols)
  } catch(IllegalArgumentException e) {
    exit 1, "error parsing '${csvFile}' line 1: ${e.message}"
  }
  
  if (lines.size() == 1) exit 1, "error parsing '${csvFile}': file does not contain data"

  def samples=[]
  for (int i = 1; i < lines.size(); i++) {
    def lineNr = i + 1

    def line = lines[i]
    if (line == null) continue;
    
    def tokens = line.split('\t', -1)
    if (tokens.length != headerTokens.length) exit 1, "error parsing '${csvFile}' line ${lineNr}: expected ${headerTokens.length} columns instead of ${tokens.length}"
    
    def sample
    try {
      sample = parseSample(tokens, colsWithIndex)
    } catch(IllegalArgumentException e) {
      exit 1, "error parsing '${csvFile}' line ${lineNr}: ${e.message}"
    }
    samples << sample
  }
  
  return samples
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
  return values.collect(value -> parseValueString(value, col))
}

def parseValueString(token, col) {
  def value = token.length() > 0 ? token : null
  if(col.required && value == null) throw new IllegalArgumentException("required value is empty")
  if(col.enum && !col.enum.contains(token) && value != null) throw new IllegalArgumentException("invalid value '${token}', valid values are [${col.enum.join(", ")}]")
  if(col.regex && col.regex != value) throw new IllegalArgumentException("invalid value '${token}' does not match regex '${col.regex}'")
  return value
}

def parseValueBoolean(token, col) {
  def value = token.length() > 0 ? token : null
  if(col.required && value == null) throw new IllegalArgumentException("required value is empty")
  
  def booleanValue
  if(value == null) booleanValue = null
  else if(value == "true") booleanValue = true
  else if(value == "false") booleanValue = false
  else throw new IllegalArgumentException("invalid value '${token}', valid values are [true, false]")
  return booleanValue
}

def parseValueFile(token, col) {
  def value = token.length() > 0 ? token : null
  if(col.required && value == null) throw new IllegalArgumentException("required value is empty")
  if(!file(value).exists()) throw new IllegalArgumentException("file '${token}' does not exist")
  if(!file(value).isFile()) throw new IllegalArgumentException("file '${token}' is not a file")
  if(col.regex && col.regex != value) throw new IllegalArgumentException("invalid value '${token}' does not match regex '${col.regex}'")
  return value
}

def parseValue(token, col) {
  def value
  switch(col.type) {
    case "string":
      value = col.list ? parseValueStringList(token, col) : parseValueString(token, col)
      break
    case "boolean":
      value = parseValueBoolean(token, col)
      break
    case "file":
      value = parseValueFile(token, col)
      break
    default:
      throw new RuntimeException("unexpected column type '${col.type}'")
  }
  return value;
}

def parseSample(tokens, cols) {
    def sample = [:]
    cols.each { colId, col -> 
      def token = col.index != null ? tokens[col.index] : ''
      try {
        sample[colId] = parseValue(token, col)
      } catch(IllegalArgumentException e) {
        throw new IllegalArgumentException("column '${colId}': ${e.message}")
      }
    }
    return sample
}
