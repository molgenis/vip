include { validateCommonParams } from './cli'

def validateParams() {
  validateCommonParams()
  validateInput()
}

// TODO support .vcf
// TODO support .bcf
def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".vcf.gz") ) exit 1, "parameter 'input' value '${params.input}' is not a .vcf.gz file"
}
