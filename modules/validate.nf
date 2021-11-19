def validateInput() {
  if( !params.containsKey('input') ) {
    println("missing required parameter 'input'")
    System.exit(1)
  }
  if( !file(params.input).exists() ) {
    println("parameter 'input' value '" + params.input + "' does not exist")
    System.exit(1)
  }
  if( !params.input.endsWith(".vcf") &&
      !params.input.endsWith(".vcf.gz") &&
      !params.input.endsWith(".bcf") &&
      !params.input.endsWith(".bcf.gz") ) {
    println("parameter 'input' value '" + params.input + "' is not a .vcf, .vcf.gz, .bcf or .bcf.gz file")
    System.exit(1)
  }
}

def validateOutput() {
  if( !params.containsKey('outputDir') ) {
    println("missing required parameter 'outputDir'")
    System.exit(1)
  }
}

def validateAssembly() {
  if( !params.containsKey('assembly') ) {
    println("missing required parameter 'assembly'")
    System.exit(1)
  }
  if( !params.assembly.equals("GRCh37") && !params.assembly.equals("GRCh38") ) {
    println("parameter 'assembly' value '" + params.assembly + "' must be 'GRCh37' or 'GRCh38'")
    System.exit(1)
  }
}

def validateReference() {
  def param =  params.assembly + ".reference"
  if( !params[params.assembly].containsKey('reference') ) {
    println("missing required parameter '" + param + "'")
    System.exit(1)
  }
  def refSeqPath = params[params.assembly].reference
  if( !file(refSeqPath).exists() ) {
    println("parameter '" + param + "' value '" + refSeqPath + "' does not exist")
    System.exit(1)
  }
  if( !refSeqPath.endsWith(".fasta.gz") &&
      !refSeqPath.endsWith(".fna.gz") &&
      !refSeqPath.endsWith(".ffn.gz") &&
      !refSeqPath.endsWith(".faa.gz") &&
      !refSeqPath.endsWith(".frn.gz") ) {
    println("parameter '" + param + "' value '" + refSeqPath + "' is not a .fasta.gz, .fna.gz, .ffn.gz, .faa.gz or .frn.gz file")
    System.exit(1)
  }
  if( !file(refSeqPath + ".fai").exists() ) {
    println("parameter '" + param + "' value '" + params.reference + ".fai' does not exist")
    System.exit(1)
  }
  if( !file(refSeqPath + ".gzi").exists() ) {
    println("parameter '" + param + "' value '" + params.reference + ".gzi' does not exist")
    System.exit(1)
  }
  // TODO: add .dict check
}

def validateAnnotate() {
  if( !params.containsKey('annotate_vep_cache_dir') ) {
    println("missing required parameter 'annotate_vep_cache_dir'")
    System.exit(1)
  }
  if( !params.annotate_vep_plugin_vkgl.isEmpty() && params.annotate_vep_plugin_vkgl_mode != 0 && params.annotate_vep_plugin_vkgl_mode != 1 ) {
    println("parameter 'annotate_vep_plugin_vkgl' requires setting parameter 'annotate_vep_plugin_vkgl_mode' to 0 or 1 (0 = consensus & lab annotations, 1 = consensus annotations)")
    System.exit(1)
  }
}

def validate() {
  validateInput()
  validateOutput()
  validateAssembly()
  validateReference()
  validateAnnotate()
}
