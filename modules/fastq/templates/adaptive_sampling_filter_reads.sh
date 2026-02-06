#!/bin/bash
set -euo pipefail

get_stop_receiving_read_ids() {
  # For files produced by MinKnow < 26:
  { grep stop_receiving "!{adaptiveSamplingCsv}" || true; } | cut -d , -f5 >> accepted_read_ids.txt
  # For files produced by MinKnow > 26:
  { grep sequence "!{adaptiveSamplingCsv}" || true; } | cut -d , -f5 >> accepted_read_ids.txt
}

concat() {
  # concatenate both compressed and uncompressed files
  zcat --force !{fastqs}
}

filter_reads() {
  # prevent writing merged fastq to disk
  concat | ${CMD_SEQTK} subseq - accepted_read_ids.txt | gzip > "!{fastqOut}"
}

main() {
  get_stop_receiving_read_ids
  filter_reads
}

main "$@"