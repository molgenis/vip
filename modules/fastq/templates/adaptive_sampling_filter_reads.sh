#!/bin/bash
set -euo pipefail

get_stop_receiving_read_ids() {
header=$(head -n1 "!{adaptiveSamplingCsv}")

# https://software-docs.nanoporetech.com/output-specifications/latest/minknow/adaptive_sampling/adaptive_sampling_decisions/
# For adaptive sampling file specification < 0.1:
if [[ "$header" == "batch_time,read_number,channel,num_samples,read_id,sequence_length,decision" ]]; then
    readIdCol=5
    statusCol=7
    version="v1"
# For adaptive sampling file specification >= 0.1:
# batch_time,...,read_id,sequence_length,decision
elif [[ "$header" == "read_id,action,action_response" ]]; then
    # read_id,action,action_response
    readIdCol=1
    statusCol=2
    responseCol=3
    version="v2"
else
    echo "ERROR: Unrecognized adaptive sampling file format: $header" >&2
    exit 1
fi

case "$version" in
  "v1")
    awk -F',' -v read_id="$readIdCol" -v status="$statusCol" '
      NR==1 {next}
      $status == "stop_receiving" {print $read_id}
    ' "!{adaptiveSamplingCsv}" > "accepted_read_ids.txt"
    ;;
  "v2")
    awk -F',' -v read_id="$readIdCol" -v status="$statusCol" -v response="$responseCol" '
      NR==1 {next}
      $status == "sequence" && $response == "SUCCESS" {print $read_id}
    ' "!{adaptiveSamplingCsv}" > "accepted_read_ids.txt"
    ;;
esac
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