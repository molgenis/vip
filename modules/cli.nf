def validateAssembly() {
  if( !params.containsKey('assembly') ) exit 1, "missing required parameter 'assembly' with value 'GRCh37' or 'GRCh38'"
  def assembly = params.assembly
  if( assembly.length() == 0 ) exit 1, "parameter 'assembly' is empty but must be 'GRCh37' or 'GRCh38'"
  if( !assembly.equals("GRCh37") && !assembly.equals("GRCh38") ) exit 1, "parameter 'assembly' value '${assembly}' must be 'GRCh37' or 'GRCh38'"
}

def validateReference() {
  def assembly = params[params.assembly]
  def reference = assembly.reference
  
  def fasta = reference.fasta
  if( !file(fasta).exists() ) exit 1, "parameter '${assembly}.reference.fasta' value '${fasta}' does not exist"
  
  def fastaFai = reference.fastaFai
  if( !file(fastaFai).exists() ) exit 1, "parameter '${assembly}.reference.fastaFai' value '${fastaFai}' does not exist"

  def fastaGzi = reference.fastaGzi
  if( !file(fastaGzi).exists() ) exit 1, "parameter '${assembly}.reference.fastaGzi' value '${fastaGzi}' does not exist"
}

def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".tsv") ) exit 1, "parameter 'input' value '${params.input}' is not a .tsv file"
}

def validateCommonParams() {
  validateAssembly()
  validateReference()
  validateInput()
}
