#!/bin/bash
set -euo pipefail

get_stop_receiving_read_ids() {
  grep stop_receiving "!{adaptiveSamplingCsv}" | cut -d , -f 5 > stop_receiving_read_ids.txt
}

concat() {
  # concatenate both compressed and uncompressed files
  zcat --force !{fastqs}
}

filter_reads() {
  # prevent writing merged fastq to disk
  concat | ${CMD_SEQTK} subseq - stop_receiving_read_ids.txt | gzip > "!{fastqOut}"
}

main() {
  get_stop_receiving_read_ids
  filter_reads
}

main "$@"