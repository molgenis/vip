def nrRecords(statsFilePath) {
  statsFilePath.readLines().collect { line -> line.split('\t').last() as int }.sum()
}