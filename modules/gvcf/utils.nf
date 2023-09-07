include { parseFastaIndex } from '../utils'

def determineChunks(meta) {
  def fastaContigs = parseFastaIndex(params[meta.project.assembly].reference.fastaFai).collectEntries { record -> [record.contig, record] }
  def records = meta.sample.gvcf.stats.readLines().collect { line -> line.split('\t') }

  int chunkSize = 10000
  int maxNrRecords = records.size() > 0 ? Math.max((records.max { record -> record[2] as int })[2] as int, chunkSize) : chunkSize

  int regionNrRecords=0
  def regions=[]
  def chunks=[]
  records.each { record ->
    def vcfContig = record[0]
    def fastaContig = fastaContigs[vcfContig]
    if(!fastaContig) {
        def fasta = params[meta.project.assembly].reference.fasta
        throw new IllegalArgumentException("vcf chromosome '${vcfContig}' does not exist in reference genome '${fasta}' (assembly '${meta.project.assembly}'). are you using the correct reference genome?")
    }
    int contigNrRecords = record[2] as int
    if(regionNrRecords + contigNrRecords <= maxNrRecords) {
      regions.add([chrom: fastaContig.contig, chromStart: 0, chromEnd: fastaContig.size])
      regionNrRecords += contigNrRecords
    }
    else {
      chunks.add(regions)
      regions=[]
      regions.add([chrom: fastaContig.contig, chromStart: 0, chromEnd: fastaContig.size])
      regionNrRecords = contigNrRecords
    }
  }
  if(regions.size > 0) {
     chunks.add(regions)
  }

  return chunks
}

def scatter(meta) {
    def chunks = determineChunks(meta)
    def index = 0
    return !chunks.isEmpty() ? chunks.collect(chunk -> [*:meta, chunk: [index: index++, regions: chunk, total: chunks.size()] ]) : [[*:meta, chunk: [index: 0, regions: [], total: 0] ]]
}