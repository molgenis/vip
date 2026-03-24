#!/bin/bash
set -euo pipefail

create_header () {
  # https://www.htslib.org/doc/samtools-addreplacerg.html is not suitable,
  # because it will overwrite existing ID field values
  
  ${CMD_SAMTOOLS} view --header-only --no-PG "!{cram}" > header.sam
  if grep --perl-regexp --quiet --max-count 1 "^@RG\t" header.sam; then
    # add or update SM field in existing RG tags
    # - remove all SM fields from RG tags
    # - add SM fields with sample identifier
    sed -E "s/(^@RG.*)\tSM:[^\t]*/\1/g" header.sam | sed -E "s/(^@RG.*)/\1\tSM:!{sampleId}/g" > header_rg_sm.sam
    
  else
    # add new RG tag with SM field (note: header.sam already ends with a newline)
    (cat header.sam && echo -e "@RG\tID:_\tSM:!{sampleId}") > header_rg_sm.sam
  fi
}

# the 'view' command serves multiple purposes
# - validating the input bam/cram/sam file
# - converting the input bam/cram/sam file to a output bam file
# - adding/updating the sample name
view () {
  local reheader_args=()
  reheader_args+=("--no-PG")
  reheader_args+=("header_rg_sm.sam")
  reheader_args+=("!{cram}")

  local view_args=()
  view_args+=("--with-header")
  view_args+=("--reference" "!{reference}")
  view_args+=("--sanitize" "off")            # perform sanity checks, but do not fix them
  view_args+=("--fast")                      # enable fast compression
  view_args+=("--bam")
  view_args+=("--output" "!{cramOut}")
  view_args+=("--no-PG")                     # do not add a @PG line to the header of the output file
  view_args+=("--threads" "!{task.cpus}")
  view_args+=("-")

  ${CMD_SAMTOOLS} reheader "${reheader_args[@]}" | ${CMD_SAMTOOLS} view "${view_args[@]}"
}

index () {
  ${CMD_SAMTOOLS} index "!{cramOut}"
  ${CMD_SAMTOOLS} idxstats "!{cramOut}" > "!{cramOutStats}"
}

main () {
  create_header
  view
  index
}

main "$@"