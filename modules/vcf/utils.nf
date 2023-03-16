include { parseFastaIndex } from '../utils'

def basename(meta) {
  return meta.chunk && meta.chunk.total > 1 ? "${meta.project_id}_chunk_${meta.chunk.index}" : meta.project_id
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
  def fastaContigs = parseFastaIndex(params[meta.assembly].reference.fastaFai).collectEntries { record -> [record.contig, record] }
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

def getVcfRegex() {
  /.+(?:\.bcf|\.bcf.gz|\.bcf\.bgz|\.vcf|\.vcf\.gz|\.vcf\.bgz|\.gvcf|\.gvcf\.gz|\.gvcf\.bgz)/
}

def isVcf(vcf) {
  vcf ==~ getVcfRegex()  
}

def getGVcfRegex() {
  /.+(?:\.g\.bcf|\.g\.bcf.gz|\.g\.vcf|\.g\.vcf\.gz|\.gvcf\.gz|\.gvcf\.bgz)/
}

def isGVcf(gVcf) {
  gVcf ==~ getGVcfRegex()
}

def preGroupTupleConcat(meta, vcf, vcfCsi, vcfStats) {
    [groupKey(meta.project_id, meta.chunk.total), [*:meta, vcf: vcf, vcf_index: vcfCsi, vcf_stats: vcfStats]]
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