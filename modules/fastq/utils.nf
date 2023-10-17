def splitPerFastqPaired(meta) {
    def index = 0;
    def size = meta.sample.fastq_r1.size();
    def meta_per_fastq = [];
    for(fastq_r1 in meta.sample.fastq_r1){
      meta_per_fastq.add([meta: meta, fastq_r1: fastq_r1, fastq_r2: meta.sample.fastq_r2.get(index), fastq_size: size, fastq_nr: index])
      index++;
    }
    return meta_per_fastq;
}

def splitPerFastqSingle(meta) {
    def meta_per_fastq = [];
    def size = meta.sample.fastq.size();
    for(fastq in meta.sample.fastq){
      meta_per_fastq.add([*:meta, sample: [*:meta.sample, fastq: fastq, fastq_size: size, fastq_nr: index]])
    }
    return meta_per_fastq;
}