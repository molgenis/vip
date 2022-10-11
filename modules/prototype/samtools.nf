process samtools_idxstats {
  executor 'local'

  input:
    tuple val(meta), path(cram), path(cramCrai)
  output:
    tuple val(meta), path(cramStats)
  script:
    cramStats="${cram}.stats"
    """
    ${CMD_SAMTOOLS} idxstats ${cram} > ${cramStats}
    """
}

def parseAlignmentStats(statsFile) {
  def lines = statsFile.readLines("UTF-8")
  if (lines.size() == 0) exit 1, "error parsing '${statsFile}': file is empty"

  def contigs = [:]
  for (int i = 0; i < lines.size(); i++) {
    def lineNr = i + 1

    def line = lines[i]
    if (line == null) continue;

    def tokens = line.split('\t', -1)
    if (tokens.length != 4) exit 1, "error parsing '${statsFile}' line ${lineNr}: expected 4 columns instead of ${tokens.length}"

    contigs[tokens[0]]=[length: tokens[1] as int, nrMappedReads: tokens[2] as int, nrUnmappedReads: tokens[3] as int]
  }
  return contigs
}

// TODO return map with all info instead of array of tokens
def parseFastaIndex(faiFile) {
  def lines = new File(faiFile).readLines("UTF-8")
  if (lines.size() == 0) exit 1, "error parsing '${faiFile}': file is empty"

  def contigs = []
  for (int i = 0; i < lines.size(); i++) {
    def lineNr = i + 1

    def line = lines[i]
    if (line == null) continue;

    def tokens = line.split('\t', -1)
    if (tokens.length != 5) exit 1, "error parsing '${faiFile}' line ${lineNr}: expected 5 columns instead of ${tokens.length}"
    
    contigs+=tokens[0]
  }
  return contigs
}
