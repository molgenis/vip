def nr_records(statsFilePath) {
  statsFilePath.readLines().collect { line -> line.split('\t').last() as int }.sum()
}

def split_determine(tuple) {
  int order = 0
  def records = tuple[tuple.size - 1].readLines().collect { line -> line.split('\t') }
  int maxNrRecords = Math.max((records.max { record -> record[2] as int })[2] as int, params.chunk_size)

  int regionNrRecords=0
  def contigs=[]
  def regions=[]
  records.each { record ->
    def contig = record[0]
    int contigNrRecords = record[2] as int
    if(regionNrRecords + contigNrRecords <= maxNrRecords) {
      contigs.add(contig)
      regionNrRecords += contigNrRecords
    }
    else {
      regions.add(contigs)
      contigs=[]
      contigs.add(contig)
      regionNrRecords = contigNrRecords
    }
  }
  if(contigs.size > 0) {
     regions.add(contigs)
  }
  
  regions.indexed().collect { index, region -> [groupKey(tuple[0], regions.size), index, region.join(','), tuple[1], tuple[2]] }
}

process split {
  input:
    tuple val(id), val(order), val(contig), path(vcfPath), path(vcfIndexPath)
  output:
    tuple val(id), val(order), path(vcfRegionPath)
  shell:
    vcfRegionPath="${id}_chunk${order}.vcf.gz"
    template 'split.sh'
}

def sort(tuple) {
  def vcfPaths = []
  tuple[1].eachWithIndex { order, idx ->
    vcfPaths[order] = tuple[2][idx]
  }
  return [tuple[0], vcfPaths]
}

process merge {
  input:
    tuple val(id), path(vcfPaths)
  output:
    tuple val(id), path(vcfMergedPath)
  shell:
    vcfMergedPath="${id}_merged.vcf.gz"
    template 'merge.sh'
}
