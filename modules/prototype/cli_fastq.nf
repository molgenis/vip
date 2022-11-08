def parseSampleSheet(csvFile) {
  def lines = new File(csvFile).readLines("UTF-8")
  if (lines.size() == 0) exit 1, "error parsing '${csvFile}': file is empty"
  
  def header = lines[0]
  def headerTokens = header.split(',', -1)
  def cols = [:]
  headerTokens.eachWithIndex { it, index -> cols[it] = index }
  
  // validate header
  if (!cols.containsKey('family_id') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'family_id' in '${header}'"
  if (!cols.containsKey('individual_id') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'individual_id' in '${header}'"
  if (!cols.containsKey('seq_method') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'seq_method' in '${header}'"
  if (!cols.containsKey('fastq_r1') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'fastq_r1' in '${header}'"
  if (!cols.containsKey('fastq_r2') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'fastq_r2' in '${header}'"

  // first pass: create family_id -> individual_id -> sample map
  def samples=[]
  for (int i = 1; i < lines.size(); i++) {
    def lineNr = i + 1

    def line = lines[i]
    if (line == null) continue;
    
    def tokens = line.split(',', -1)
    if (tokens.length != headerTokens.length) exit 1, "error parsing '${csvFile}' line ${lineNr}: expected ${headerTokens.length} columns instead of ${tokens.length}"
    
    def familyId = tokens[cols["family_id"]]
    if (familyId.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'family_id' cannot be empty"

    def individualId = tokens[cols["individual_id"]]
    if (individualId.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'individual_id' cannot be empty"

    def paternalId
    if (cols.containsKey("paternal_id")) {
      paternalId = tokens[cols["paternal_id"]]
      if (paternalId.length() == 0 ) paternalId = null
    }

    def maternalId
    if (cols.containsKey("maternal_id")) {
      maternalId = tokens[cols["maternal_id"]]
      if (maternalId.length() == 0 ) maternalId = null
    }
    
    if (paternalId != null && maternalId != null && paternalId == maternalId) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'paternal_id' and 'maternal_id' cannot be equal"

    def proband
    if (cols.containsKey("proband")) {
      proband = tokens[cols["proband"]]
      if (proband.length() == 0 || proband == "false") proband=false
      else if(proband == "true") proband=true
      else exit 1, "error parsing '${csvFile}' line ${lineNr}: invalid 'proband' value '${proband}'. valid values are 'true', 'false' or empty"
    }
    
    def hpoTerms=[]
    if (cols.containsKey("hpo_terms")) {
      hpoTerms = tokens[cols["hpo_terms"]]
      if (hpoTerms.length() == 0) hpoTerms=[]
      else {
        def hpoTermTokens = hpoTerms.split(";", -1)
        hpoTermTokens.each { token -> 
          if(token != /HP:\d{7}/) "error parsing '${csvFile}' line ${lineNr}: invalid 'hpo_terms' value '${hpoTerms}'. valid values are semi-colon separated HPO terms"
        }
        hpoTerms = hpoTermTokens
      }
    }

    def seqMethod = tokens[cols["seq_method"]]
    if (seqMethod.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'seqMethod' cannot be empty"
    if (seqMethod != "WES" && seqMethod != "WGS") exit 1, "error parsing '${csvFile}' line ${lineNr}: invalid 'seq_method' value '${seqMethod}'. valid values are 'WES' or 'WGS'"

    def fastqR1 = tokens[cols["fastq_r1"]]
    if (fastqR1.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r1' cannot be empty"
    fastqR1=file(fastqR1)
    if (!fastqR1.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r1' '${fastqR1}' does not exist"
    if (!fastqR1.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r1' '${fastqR1}' is not a file"

    def fastqR2 = tokens[cols["fastq_r2"]]
    if (fastqR2.length() == 0 ) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r2' cannot be empty"
    fastqR2=file(fastqR2)
    if (!fastqR2.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r2' '${fastqR2}' does not exist"
    if (!fastqR2.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'fastq_r2' '${fastqR2}' is not a file"

    def sample = [:]
    // sample["sample_sheet_line"] = lineNr
    sample["family_id"] = familyId
    sample["individual_id"] = individualId
    sample["paternal_id"] = paternalId
    sample["maternal_id"] = maternalId
    sample["proband"] = proband
    sample["hpo_terms"] = hpoTerms
    sample["seq_method"] = seqMethod
    sample["fastq_r1"] = fastqR1
    sample["fastq_r2"] = fastqR2

    samples << sample
  }
  
  return samples
}

def countFamilySamples(sample, sampleSheet) {
    sampleSheet.count { thisSample -> sample.family_id == thisSample.family_id }
}

def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".csv") ) exit 1, "parameter 'input' value '${params.input}' is not a .csv file"
}

def validateReference() {
  if( !params.containsKey('reference') )   exit 1, "missing required parameter 'reference'"
  if( !file(params.reference).exists() )   exit 1, "parameter 'reference' value '${params.reference}' does not exist"
  
  def referenceFai = params.reference + ".fai"
  if( !file(referenceFai).exists() )   exit 1, "parameter 'reference' value '${params.reference}' index '${referenceFai}' does not exist"

  def referenceGzi = params.reference + ".gzi"
  if( !file(referenceGzi).exists() )   exit 1, "parameter 'reference' value '${params.reference}' index '${referenceGzi}' does not exist"

  def referenceMmi = params.reference + ".mmi"
  if( !file(referenceMmi).exists() )   exit 1, "parameter 'reference' value '${params.reference}' index '${referenceMmi}' does not exist"
}

def validateParams() {
  validateInput()
  validateReference()
}