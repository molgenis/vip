#!/bin/bash
set -euo pipefail

get_stop_receiving_read_ids() {
  grep stop_receiving "!{adaptiveSamplingCsv}" | cut -d , -f 5 > stop_receiving_read_ids.txt
}

filter_reads() {
  zcat "!{fastq}" | ${CMD_SEQTK} subseq - stop_receiving_read_ids.txt | gzip > "!{fastqOut}"
}

main() {
  get_stop_receiving_read_ids
  filter_reads
}

main "$@"