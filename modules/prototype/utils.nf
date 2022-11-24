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
    
    contigs += [contig: tokens[0], size: tokens[1] as long, location: tokens[2] as long, basesPerLine: tokens[3] as long, bytesPerLine: tokens[4] as long]
  }
  return contigs
}

def determineChunks(meta) {
    def records = parseFastaIndex(params[params.assembly].reference.fastaFai)

    long sizeMax = records.max{ record -> record.size }.size
    long size = 0L;
    
    def chunks = []
    def regions = []
    records.each { record -> 
        size += record.size
        if(size > sizeMax) {
            chunks.add(regions)
            regions = []
            size = 0L
        }
        regions.add([chrom: record.contig, chromStart: 0, chromEnd: record.size])
    }
    if(regions.size() > 0) {
        chunks.add(regions)
    }

    return chunks
}

def scatter(meta) {
    def chunks = determineChunks(meta)
    def index = 0
    chunks.collect(chunk -> [*:meta, chunk: [index: index++, regions: chunk, total: chunks.size()] ])
}

def findVcfIndex(vcf) {
    def vcf_index
    if(file(vcf + ".csi").exists()) vcf_index = vcf + ".csi"
    if(file(vcf + ".tbi").exists()) vcf_index = vcf + ".tbi"
    vcf_index
}

def findCramIndex(cram) {
    def cram_index
    if(file(cram + ".crai").exists()) cram_index = cram + ".crai"
    cram_index
}
