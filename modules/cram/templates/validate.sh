#!/bin/bash
set -euo pipefail

# the 'view' command serves two purposes
# - validating the input bam/cram/sam file
# - converting the input bam/cram/sam file to a output bam file
view () {
  local args=()
  args+=("--with-header")
  args+=("--reference" "!{reference}")
  args+=("--sanitize" "off")            # perform sanity checks, but do not fix them
  args+=("--fast")                      # enable fast compression
  args+=("--bam")
  args+=("--output" "!{cramOut}")
  args+=("--no-PG")                     # do not add a @PG line to the header of the output file
  args+=("--threads" "!{task.cpus}")
  args+=("!{cram}")

  ${CMD_SAMTOOLS} view "${args[@]}"
}

index () {
  ${CMD_SAMTOOLS} index "!{cramOut}"
  ${CMD_SAMTOOLS} idxstats "!{cramOut}" > "!{cramOutStats}"
}

main () {
  view
  index
}

main "$@"