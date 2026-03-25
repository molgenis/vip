#!/bin/bash
set -euo pipefail

align() {
  # minimap2
  local minimap2_args=()
  minimap2_args+=("-t" "!{task.cpus}")
  minimap2_args+=("-a")
  # MarkDuplicates uses the LB (= DNA preparation library identifier) field to determine which read groups might contain molecular duplicates, in case the same DNA library was sequenced on multiple lanes.
  minimap2_args+=("-R" "@RG\tID:$(basename !{fastqR1})\tPL:!{platform}\tLB:!{sampleId}\tSM:!{sampleId}")
  minimap2_args+=("-x" "sr")
  if [[ "!{softClipping}" == "true" ]]; then
      minimap2_args+=("-Y")
  fi
  minimap2_args+=("!{referenceMmi}")
  minimap2_args+=("!{fastqR1}")
  minimap2_args+=("!{fastqR2}")

  # samtools fixmate
  local samtools_fixmate_args=()
  samtools_fixmate_args+=("-u")                           # uncompressed output
  samtools_fixmate_args+=("-m")                           # add ms (mate score) tags, used by markdup to select the best reads to keep
  samtools_fixmate_args+=("-@" "!{task.cpus}")            # number of input/output compression threads to use in addition to main thread
  samtools_fixmate_args+=("--no-PG")                      # do not add a @PG line to the header of the output file
  samtools_fixmate_args+=("-")                            # read input from standard input
  samtools_fixmate_args+=("-")                            # write output to standard output

  # samtools sort
  local samtools_sort_args=()
  samtools_sort_args+=("-u")                              # uncompressed output
  samtools_sort_args+=("--reference" "!{reference}")      # fasta format reference file
  samtools_sort_args+=("--no-PG")                         # do not add a @PG line to the header of the output file
  samtools_sort_args+=("-@" "!{task.cpus}")               # number of sorting and compression threads
  samtools_sort_args+=("-")                               # read input from standard input

  # samtools view
  local samtools_view_args=()
  samtools_view_args+=("--output-fmt" "cram,version=3.0") # some downstream tools do not support 3.1
  samtools_view_args+=("--output" "!{cram}")              # output file
  if [[ -n "!{bedFile}" ]]; then
    samtools_view_args+=("--target-file" "!{bedFile}")    # only output alignments overlapping the input .bed file
  fi
  samtools_view_args+=("--reference" "!{reference}")      # fasta format reference file
  samtools_view_args+=("--write-index")                   # index creation
  samtools_view_args+=("--no-PG")                         # do not add a @PG line to the header of the output file
  samtools_view_args+=("--threads" "!{task.cpus}")        # number of compression threads to use in addition to main thread
  samtools_view_args+=("-")                               # read input from standard input

  if [[ "!{markDuplicates}" == "true" ]]; then
    # samtools markdup
    local samtools_markdup_args=()
    samtools_markdup_args+=("-u")                         # uncompressed output
    samtools_markdup_args+=("-@" "!{task.cpus}")          # number of input/output compression threads to use in addition to main thread
    samtools_markdup_args+=("--reference" "!{reference}") # fasta format reference file
    samtools_markdup_args+=("--no-PG")                    # do not add a PG line to the output file
    samtools_markdup_args+=("-")                          # read input from standard input
    samtools_markdup_args+=("-")                          # write output to standard output

    ${CMD_MINIMAP2} "${minimap2_args[@]}" | \
      ${CMD_SAMTOOLS} fixmate "${samtools_fixmate_args[@]}" | \
      ${CMD_SAMTOOLS} sort "${samtools_sort_args[@]}" | \
      ${CMD_SAMTOOLS} markdup "${samtools_markdup_args[@]}" | \
      ${CMD_SAMTOOLS} view "${samtools_view_args[@]}"
  else
    ${CMD_MINIMAP2} "${minimap2_args[@]}" | \
      ${CMD_SAMTOOLS} fixmate "${samtools_fixmate_args[@]}" | \
      ${CMD_SAMTOOLS} sort "${samtools_sort_args[@]}" | \
      ${CMD_SAMTOOLS} view "${samtools_view_args[@]}"
  fi
}

stats() {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  align
  stats
}

main "$@"
