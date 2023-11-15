def validateAssemblies(inputAssemblies, outputAssemblies) {
  def assemblies = (inputAssemblies + outputAssemblies).unique()
  
  assemblies.each { assembly ->
    def reference = params[assembly].reference
    
    def fasta = reference.fasta
    if( fasta.isEmpty() ) exit 1, "parameter '${assembly}.reference.fasta' value is undefined, but required because '${assembly}' is referenced in '${params.input}'"
    if( !file(fasta).exists() ) exit 1, "parameter '${assembly}.reference.fasta' value '${fasta}' does not exist"
    
    def fastaFai = reference.fastaFai
    if( fastaFai.isEmpty() ) exit 1, "parameter '${assembly}.reference.fastaFai' value is undefined, but required because '${assembly}' is referenced in '${params.input}'"
    if( !file(fastaFai).exists() ) exit 1, "parameter '${assembly}.reference.fastaFai' value '${fastaFai}' does not exist"

    def fastaGzi = reference.fastaGzi
    if( fastaGzi.isEmpty() ) exit 1, "parameter '${assembly}.reference.fastaGzi' value is undefined, but required because '${assembly}' is referenced in '${params.input}'"
    if( !file(fastaGzi).exists() ) exit 1, "parameter '${assembly}.reference.fastaGzi' value '${fastaGzi}' does not exist"
  }

  inputAssemblies.each { inputAssembly ->
    outputAssemblies.each { outputAssembly ->
      if(inputAssembly != outputAssembly) {
        def chain = params[inputAssembly].chain[outputAssembly]
        if( chain.isEmpty() ) exit 1, "parameter '${inputAssembly}.chain.${outputAssembly}' value is undefined, but required"
        if( !file(chain).exists() ) exit 1, "parameter '${inputAssembly}.chain.${outputAssembly}' value '${chain}' does not exist"
      }
    }
  }
}

def validateInput() {
  if( !params.containsKey('input') )   exit 1, "missing required parameter 'input'"
  if( !file(params.input).exists() )   exit 1, "parameter 'input' value '${params.input}' does not exist"
  if( !params.input.endsWith(".tsv") ) exit 1, "parameter 'input' value '${params.input}' is not a .tsv file"
}

def validateCommonParams(inputAssemblies) {
  validateInput()

  def outputAssembly = params.assembly
  if (!(outputAssembly ==~ /GRCh38/))  exit 1, "parameter 'params.assembly' value '${outputAssembly}' is invalid. allowed values are [GRCh38]"
  
  validateAssemblies(inputAssemblies, [outputAssembly])
}
