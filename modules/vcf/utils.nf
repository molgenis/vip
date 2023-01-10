def basename(meta) {
  return meta.chunk ? "${meta.project_id}_chunk_${meta.chunk.index}" : meta.project_id
}

def nrRecords(statsFilePath) {
  // stats file only contains counts for contigs with at least one record
  def lines = statsFilePath.readLines()
  return !lines.isEmpty() ? lines.collect { line -> line.split('\t').last() as int }.sum() : 0
}

def getProbands(samples) {
  samples.findAll{ sample -> sample.proband }.collect{ sample -> [family_id:sample.family_id, individual_id:sample.individual_id] }
}

def getHpoIds(samples) {
  samples.collectMany { sample -> sample.hpo_ids }.unique()
}