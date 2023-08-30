include { parseFastaIndex } from '../utils'

def basename(meta) {
  return meta.chunk && meta.chunk.total > 1 ? "${meta.project.id}_chunk_${meta.chunk.index}" : meta.project.id
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

def getProbandHpoIds(samples) {
  samples.findAll{ sample -> sample.proband }.collectMany { sample -> sample.hpo_ids }.unique()
}

def areProbandHpoIdsIndentical(samples) {
  def hpo_ids=[]
  def isIdentical = true
  samples.findAll{ sample -> sample.proband }.each{ sample ->
    if(hpo_ids.isEmpty() && !sample.hpo_ids.isEmpty()){
      hpo_ids = sample.hpo_ids
    }else{
      if(sample.hpo_ids as Set != hpo_ids as Set){
        isIdentical = false
      }
    }
  }
  return isIdentical;
}

def determineChunks(meta) {
  def fastaContigs = parseFastaIndex(params[meta.project.assembly].reference.fastaFai).collectEntries { record -> [record.contig, record] }
  def records = meta.vcf.stats.readLines().collect { line -> line.split('\t') }

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

def preGroupTupleConcat(meta, vcf, vcfCsi, vcfStats) {
    [groupKey(meta.project.id, meta.chunk.total), [*:meta, vcf: vcf, vcf_index: vcfCsi, vcf_stats: vcfStats]]
}

def postGroupTupleConcat(key, metaList) {
  def filteredMetaList = metaList.findAll { meta -> nrRecords(meta.vcf_stats) > 0 }
  def meta, vcfs, vcfIndexes
  if(filteredMetaList.size() == 0) {
    meta = metaList.first()
    vcfs = [meta.vcf]
    vcfIndexes = [meta.vcf_index]
  }
  else if(filteredMetaList.size() == 1) {
    meta = filteredMetaList.first()
    vcfs = [meta.vcf]
    vcfIndexes = [meta.vcf_index]
  }
  else {
    def sortedMetaList = filteredMetaList.sort { metaLeft, metaRight -> metaLeft.chunk.index <=> metaRight.chunk.index }
    meta = sortedMetaList.first()
    vcfs = sortedMetaList.collect { it.vcf }
    vcfIndexes = sortedMetaList.collect { it.vcf_index }
  }
  meta = [*:meta].findAll { it.key != 'vcf' && it.key != 'vcf_index' && it.key != 'vcf_stats' && it.key != 'chunk' }
  return [meta, vcfs, vcfIndexes]
}