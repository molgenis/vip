def nrRecords(statsFilePath) {
  statsFilePath.readLines().collect { line -> line.split('\t').last() as int }.sum()
}

def getProbands(samples) {
  samples.findAll{ sample -> sample.proband }.collect{ sample -> [family_id:sample.family_id, individual_id:sample.individual_id] }
}

def getHpoIds(samples) {
  samples.collectMany { sample -> sample.hpo_ids }.unique()
}