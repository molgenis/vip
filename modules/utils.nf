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
    def records = parseFastaIndex(params[meta.sample.assembly].reference.fastaFai)

    long sizeMax = records.max{ record -> record.size }.size
    long size = 0L;
    
    def chunks = []
    def regions = []
    records.each { record -> 
        if(size + record.size > sizeMax) {
            chunks.add(regions)
            regions = []
            size = 0L
        }
        size += record.size
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
    def vcfIndex
    if(vcf == null) vcfIndex = null
    else if(file(vcf + ".csi").exists()) vcfIndex = vcf + ".csi"
    else if(file(vcf + ".tbi").exists()) vcfIndex = vcf + ".tbi"
    vcfIndex
}

def createPedigree(sampleSheet) {
    sampleSheet.collect{ sample ->
        def sex = sample.sex == "male" ? 1 : (sample.sex == "female" ? 2 : 0)
        def affected = sample.affected == false ? 1 : (sample.affected == true ? 2 : 0)
        [sample.family_id, sample.individual_id, sample.paternal_id ?: 0, sample.maternal_id ?: 0, sex, affected].join("\t")
    }.join("\n")
}