def nrMappedReads(statsFilePath) {
  def lines = statsFilePath.readLines()*.split('\t')
  return !lines.isEmpty() ? lines.collect { line -> line[2] as int }.sum() : 0
}

def nrMappedReadsInChunk(chunk, statsFilePath) {
  def contigs = chunk.regions.collect { region -> region.chrom } as Set
  def lines = statsFilePath.readLines()*.split('\t')
  return !lines.isEmpty() ? lines.findAll { line -> contigs.contains(line[0]) }.collect { line -> line[2] as int }.sum() : 0
}