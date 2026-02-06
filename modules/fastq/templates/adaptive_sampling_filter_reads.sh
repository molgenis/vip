#!/bin/bash
set -euo pipefail

get_stop_receiving_read_ids() {
  echo "1"
  # For files produced by MinKnow < 26:
  { grep stop_receiving "!{adaptiveSamplingCsv}" || true; } | cut -d , -f5 >> accepted_read_ids.txt
  echo "2"
  # For files produced by MinKnow > 26:
  { grep sequence "!{adaptiveSamplingCsv}" || true; } | cut -d , -f5 >> accepted_read_ids.txt
  echo "3"
}

concat() {
  echo "5"
  # concatenate both compressed and uncompressed files
  zcat --force !{fastqs}
}

filter_reads() {
  echo "4"
  # prevent writing merged fastq to disk
  concat | ${CMD_SEQTK} subseq - accepted_read_ids.txt | gzip > "!{fastqOut}"
}

main() {
  echo "0"
  get_stop_receiving_read_ids
  filter_reads
}

main "$@"