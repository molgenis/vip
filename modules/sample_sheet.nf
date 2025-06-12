def parseHpoPhenotypicAbnormality(hpoPhenotypicAbnormalityFilename) {
  def hpoFile = new File(hpoPhenotypicAbnormalityFilename)

  def lines = hpoFile.readLines("UTF-8")
	if (lines.size() == 0) exit 1, "error parsing '${hpoPhenotypicAbnormalityFilename}': file is empty"

	if (lines[0] != "id\tlabel\tdescription") {
	  exit 1, "error parsing '${hpoPhenotypicAbnormalityFilename}': file header invalid, expected 'id<tab>label<description>'"
	}

	def hpoTermIds=[:]
	for (int i = 1; i < lines.size(); i++) {
		def lineNr = i + 1

		def line = lines[i]
		if (line == null) continue;

		def tokens = line.split('\t', -1)
		if (tokens.length != 3) exit 1, "error parsing '${hpoPhenotypicAbnormalityFilename}' line ${lineNr}: expected 3 columns instead of ${tokens.length}"

		def hpoTermId=tokens[0]
		hpoTermIds[hpoTermId]=null
	}
	return hpoTermIds
}

def parseCommonSampleSheet(csvFilename, hpoPhenotypicAbnormalityFilename, additionalCols) {
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
      default: { "fam${seq_nr++}" },
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
    regions: [
      type: "file",
      scope: "project",
      regex: /.+(?:\.bed)/
    ],
    sequencing_method: [
      type: "string",
      default: { 'WGS' },
      enum: ['WES', 'WGS'],
      scope: "project"
    ],
    pcr_performed: [
      type: "boolean",
      default: { 'false' },
      scope: "project"
    ]
  ]

  def cols = [*:commonCols, *:additionalCols]

  def hpoTermIdMap = parseHpoPhenotypicAbnormality(hpoPhenotypicAbnormalityFilename)

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
      sample = parseSample(tokens, colsWithIndex, csvFile.getParentFile(), hpoTermIdMap)
    } catch(IllegalArgumentException e) {
      exit 1, "error parsing '${csvFilename}' line ${lineNr}: ${e.message}"
    }
    sample.index = i
    samples << sample
  }

  def projects
  try {
    projects = parseProjects(samples, cols)
    projects.each { project -> validate(project)}
  } catch(IllegalArgumentException e) {
    exit 1, "error parsing '${csvFilename}': ${e.message}"
  }

  return projects
}

def validate(project){
  def sampleMap = [:]
  project.samples.each{ sample ->
    if(sampleMap[[id: sample.individual_id]] != null)  throw new IllegalArgumentException("line ${sample.index}: individual_id '${sample.individual_id}' already exists in project '${project.id}', individual_id should be unique within a project.")
    sampleMap[[id: sample.individual_id]] = [familyId : sample.family_id, sex: sample.sex]
  }
  project.samples.each{ sample ->
    if(sample.paternal_id != null){
      if(sample.individual_id == sample.paternal_id) throw new IllegalArgumentException("line ${sample.index}: individual_id '${sample.individual_id}' cannot be the same as paternal_id '${sample.paternal_id}'")

      def paternal_sample = sampleMap[[id: sample.paternal_id]]
      if(paternal_sample == null) throw new IllegalArgumentException("line ${sample.index}: paternal_id sample '${sample.paternal_id}' for sample '${sample.individual_id}' is not present in project '${project.id}'.")
      if(paternal_sample.familyId != sample.family_id) throw new IllegalArgumentException("line ${sample.index}: paternal_id sample '${sample.paternal_id}' for sample '${sample.individual_id}' belongs to a different family. hint: add or update column 'family_id'.")
      if(paternal_sample.sex == "female") throw new IllegalArgumentException("line ${sample.index}: paternal_id sample '${sample.paternal_id}' refers to sample with female sex.")
    }
    if(sample.maternal_id != null){
      if(sample.individual_id == sample.maternal_id) throw new IllegalArgumentException("line ${sample.index}: individual_id '${sample.individual_id}' cannot be the same as maternal_id '${sample.maternal_id}'")

      def maternal_sample = sampleMap[[id: sample.maternal_id]]
      if(maternal_sample == null) throw new IllegalArgumentException("line ${sample.index}: maternal_id sample '${sample.maternal_id}' for sample '${sample.individual_id}' is not present in project '${project.id}'.")
      if(maternal_sample.familyId != sample.family_id) throw new IllegalArgumentException("line ${sample.index}: maternal_id sample '${sample.maternal_id}' for sample '${sample.individual_id}' belongs to a different family.")
      if(maternal_sample.sex == "male") throw new IllegalArgumentException("line ${sample.index}: maternal_id sample '${sample.maternal_id}' refers to sample with male sex.")
    }
    if(sample.paternal_id != null && sample.maternal_id != null){
      if(sample.paternal_id == sample.maternal_id) throw new IllegalArgumentException("line ${sample.index}: paternal_id '${sample.paternal_id}' cannot be the same as maternal_id '${sample.maternal_id}'")
    }
  }
  def pcr = project.pcr_performed
  if (!(pcr ==~ /true|false/))  exit 1, "parameter 'project.pcr_performed' value '${pcr}' is invalid. allowed values are [true, false]"
  
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
    def relative = !value.startsWith('/')
    value = value.replaceAll(/\[/, '\\\\[').replaceAll(/\]/, '\\\\]').replaceAll(/\}/, '\\\\}').replaceAll(/\{/, '\\\\{')
    
    fileValue = relative ? file(new File(value, rootDir).getPath()) : file(value)
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

def parseSample(tokens, cols, rootDir, hpoTermIdMap) {
    def sample = [:]
    cols.each { colId, col -> 
      def token = col.index != null ? tokens[col.index] : ''
      try {
        def value = parseValue(token, col, rootDir)
        if(colId == "hpo_ids") {
        	value.each { hpoTermId ->
        	  if(!hpoTermIdMap.containsKey(hpoTermId)) {
        	    throw new IllegalArgumentException("HPO term '${hpoTermId}' is not a child of 'HP:0000118' (phenotypic abnormality)")
        	  }
        	}
        }

        sample[colId] = value
      } catch(IllegalArgumentException e) {
        throw new IllegalArgumentException("column '${colId}': ${e.message}")
      }
    }
    return sample
}

def parseProjects(samples, cols) {
  def colIds = cols.findAll { it.value.scope == 'project' }.collect([] as Set){ it.key }
  
  // group samples by project id
  def samplesByProject = [:]
  samples.each { sample -> 
    def projectSamples = samplesByProject[sample.project_id]
    if(projectSamples == null) {
      projectSamples = []
      samplesByProject[sample.project_id] = projectSamples
    }
    projectSamples.push([*:sample].findAll { it.key != 'project_id'})
  }
  
  // create projects
  def projects = []
  samplesByProject.each { projectId, projectSamples -> 
    def project = [id: projectId]
    colIds.each { colId ->
        def colValues = projectSamples.unique(false) { it[colId] }
        if(colValues.size() > 1) {
            throw new IllegalArgumentException("project '${projectId}' column '${colId}' values must be equal for all project samples")
        }
        project[colId] = projectSamples.first()[colId]
    }
    project.samples = projectSamples.collect { projectSample -> projectSample.findAll { !colIds.contains(it.key) } }
    projects << project
  }

  return projects
}

def getAssemblies(projects) {
  projects.collect(project -> project.containsKey("assembly") ? [project.assembly] : project.samples.collect { sample -> sample.assembly }).flatten().unique()
}