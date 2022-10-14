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
  if (!cols.containsKey('paternal_id') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'paternal_id' in '${header}'"
  if (!cols.containsKey('maternal_id') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'maternal_id' in '${header}'"
  if (!cols.containsKey('proband') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'proband' in '${header}'"
  if (!cols.containsKey('seq_method') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'seq_method' in '${header}'"
  if (!cols.containsKey('fastq_r1') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'fastq_r1' in '${header}'"
  if (!cols.containsKey('fastq_r2') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'fastq_r2' in '${header}'"
  if (!cols.containsKey('cram') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'cram' in '${header}'"
  if (!cols.containsKey('g_vcf') ) exit 1, "error parsing '${csvFile}' line 1: missing column 'g_vcf' in '${header}'"

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

    def paternalId = tokens[cols["paternal_id"]]
    if (paternalId.length() == 0 ) paternalId = null

    def maternalId = tokens[cols["maternal_id"]]
    if (maternalId.length() == 0 ) maternalId = null
    
    if (paternalId != null && maternalId != null && paternalId == maternalId) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'paternal_id' and 'maternal_id' cannot be equal"

    def proband = tokens[cols["proband"]]
    if (proband.length() == 0 || proband == "false") proband=false
    else if(proband == "true") proband=true
    else exit 1, "error parsing '${csvFile}' line ${lineNr}: invalid 'proband' value '${proband}'. valid values are 'true', 'false' or empty"

    def hpoTerms = tokens[cols["hpo_terms"]]
    if (hpoTerms.length() == 0) hpoTerms=[]
    else {
      def hpoTermTokens = hpoTerms.split(";", -1)
      hpoTermTokens.each { token -> 
        if(token != /HP:\d{7}/) "error parsing '${csvFile}' line ${lineNr}: invalid 'hpo_terms' value '${hpoTerms}'. valid values are semi-colon separated HPO terms"
      }
      hpoTerms = hpoTermTokens
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

    def cram = tokens[cols["cram"]]
    def cramIndex
    if (cram.length() ==  0) {
      cram = null
      cramIndex = null
    }
    else {
      cram=file(cram)
      if (!cram.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'cram' '${cram}' does not exist"
      if (!cram.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'cram' '${cram}' is not a file"
      
      cramIndex = file(cram + ".crai")
      if (!cramIndex.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'cram' '${cramIndex}' does not exist"
      if (!cramIndex.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'cram' '${cramIndex}' is not a file"
    }

    def gVcf = tokens[cols["g_vcf"]]
    def gVcfIndex
    if (gVcf.length() == 0) {
      gVcf = null
      gVcfIndex = null
    } else {
      gVcf=file(gVcf)
      if (!gVcf.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'g_vcf' '${gVcf}' does not exist"
      if (!gVcf.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'g_vcf' '${gVcf}' is not a file"

      gVcfIndex = file(gVcf + ".csi")
      if (!gVcfIndex.exists()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'g_vcf' '${gVcfIndex}' does not exist"
      if (!gVcfIndex.isFile()) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'g_vcf' '${gVcfIndex}' is not a file"
    }

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
    sample["cram"] = cram
    sample["cram_index"] = cramIndex
    sample["g_vcf"] = gVcf
    sample["g_vcf_index"] = gVcfIndex
    samples << sample
  }
  
  // FIXME 2nd pass validation
  //   def family = samples[familyId]
  //   if (family == null) {
  //     family = [:]
  //     samples[familyId] = family
  //   }
    
  //   def individual = family[individualId]
  //   if (individual != null) exit 1, "error parsing '${csvFile}' line ${lineNr}: 'family_id/individual_id' '${familyId}/${individualId}' already exists on line ${individual.sample_sheet_line}"
    
  //   family[individualId] = sample
  // // second pass: validate paternal_id and maternal_id
  // samples.each { familyEntry -> familyEntry.value.each { individualEntry ->
  //     def individual = individualEntry.value

  //     def paternalId = individual["paternal_id"]
  //     if (paternalId != null) {
  //       def father = familyEntry.value[paternalId]
  //       if (father == null) {
  //         System.err.println "warning parsing '${csvFile}' line ${individual.sample_sheet_line}: 'paternal_id' '${paternalId}' does not exist within the same family, ignoring..."
  //         individual["paternal_id"] = null
  //       }
  //     }

  //     def maternalId = individual["maternal_id"]
  //     if (maternalId != null) {
  //       def mother = familyEntry.value[maternalId]
  //       if (mother == null) {
  //         System.err.println "warning parsing '${csvFile}' line ${individual.sample_sheet_line}: 'maternal_id' '${maternalId}' does not exist within the same family, ignoring..."
  //         individual["maternal_id"] = null
  //       }
  //     }
      
  //     individual.remove("sample_sheet_line")
  //   }
  // }  
  
  return samples
}
