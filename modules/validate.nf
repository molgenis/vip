def validateInput() {
  if( !params.containsKey('input') ) {
    println("missing required parameter 'input'")
    System.exit(1)
  }
  if( !file(params.input).exists() ) {
    println("parameter 'input' value '" + params.input + "' does not exist")
    System.exit(1)
  }
  if( !params.input.endsWith(".vcf.gz") ) {
    println("parameter 'input' value '" + params.input + "' is not a .vcf.gz file")
    System.exit(1)
  }
}

def validateOutput() {
  if( !params.containsKey('outputDir') ) {
    println("missing required parameter 'outputDir'")
    System.exit(1)
  }
}

def validateReference() {
  if( !params.containsKey('reference') ) {
    println("missing required parameter 'reference'")
    System.exit(1)
  }
  if( !file(params.reference).exists() ) {
    println("parameter 'reference' value '" + params.reference + "' does not exist")
    System.exit(1)
  }
  if( !params.reference.endsWith(".fasta.gz") &&
      !params.reference.endsWith(".fna.gz") &&
      !params.reference.endsWith(".ffn.gz") &&
      !params.reference.endsWith(".faa.gz") &&
      !params.reference.endsWith(".frn.gz") ) {
    println("parameter 'reference' value '" + params.reference + "' is not a .fasta.gz, .fna.gz, .ffn.gz, .faa.gz or .frn.gz file")
    System.exit(1)
  }
  if( !file(params.reference + ".fai").exists() ) {
    println("parameter 'reference' value '" + params.reference + ".fai' does not exist")
    System.exit(1)
  }
  if( !file(params.reference + ".gzi").exists() ) {
    println("parameter 'reference' value '" + params.reference + ".gzi' does not exist")
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
  validateReference()
  validateAnnotate()
}
