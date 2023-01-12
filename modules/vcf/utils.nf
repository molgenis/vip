include { parseFastaIndex } from '../utils'

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

def determineChunks(meta) {
  def fastaContigs = parseFastaIndex(params[params.assembly].reference.fastaFai).collectEntries { record -> [record.contig, record] }
  def records = meta.vcf_stats.readLines().collect { line -> line.split('\t') }
  
  int chunkSize = 10000
  int maxNrRecords = records.size() > 0 ? Math.max((records.max { record -> record[2] as int })[2] as int, chunkSize) : chunkSize

  int regionNrRecords=0
  def regions=[]
  def chunks=[]
  records.each { record ->
    def fastaContig = fastaContigs[record[0]]
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