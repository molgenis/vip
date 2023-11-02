def splitPerFastqPaired(meta) {
    def index = 0;
    def total = meta.sample.fastq_r1.size();
    def meta_per_fastq = [];
    for(fastq_r1 in meta.sample.fastq_r1){
      meta_per_fastq.add([*:meta, sample: [*:meta.sample, fastq: [data_r1: fastq_r1, data_r2: meta.sample.fastq_r2.get(index), total: total, index: index]]])
      index++;
    }
    return meta_per_fastq;
}

def splitPerFastqSingle(meta) {
    def meta_per_fastq = [];
    def total = meta.sample.fastq.size();
    for(fastq in meta.sample.fastq){
      meta_per_fastq.add([*:meta, sample: [*:meta.sample, fastq: [data: fastq, total: total, index: index]]])
    }
    return meta_per_fastq;
}