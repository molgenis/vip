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