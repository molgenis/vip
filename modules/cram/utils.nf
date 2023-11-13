def nrMappedReads(statsFilePath) {
  def lines = statsFilePath.readLines()*.split('\t')
  return !lines.isEmpty() ? lines.collect { line -> line[2] as int }.sum() : 0
}

def nrMappedReadsInChunk(chunk, statsFilePath) {
  def contigs = chunk.regions.collect { region -> region.chrom } as Set
  def lines = statsFilePath.readLines()*.split('\t')
  return !lines.isEmpty() ? lines.findAll { line -> contigs.contains(line[0]) }.collect { line -> line[2] as int }.sum() : 0
}

def getPaternalCram(sample, family) {
  if(sample.paternal_id == null) return null
  return family.samples.find { it.family_id == sample.family_id && it.individual_id == sample.paternal_id }.cram
}

def getMaternalCram(sample, family) {
  if(sample.maternal_id == null) return null
  return family.samples.find { it.family_id == sample.family_id && it.individual_id == sample.maternal_id }.cram
}