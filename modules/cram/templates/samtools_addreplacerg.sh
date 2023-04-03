#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

create_cram_slice () {
  local args=()
  args+=("view")
  args+=("--cram")
  args+=("--output" "!{cram.simpleName}_sliced.cram")
  args+=("--target-file" "!{bed}")
  args+=("--reference" "!{reference}")
  args+=("--write-index")
  args+=("--no-PG")
  args+=("--threads" "!{task.cpus}")
  args+=("!{cram}")

  ${CMD_SAMTOOLS} "${args[@]}"
}

add_replace_read_group () {
  tab=$'\t';
  ${CMD_SAMTOOLS} addreplacerg -r "@RG${tab}ID:!{meta.sample.individual_id}${tab}SM:!{meta.sample.individual_id}" -o "!{cramOut}" --threads "!{task.cpus}" "!{cram.simpleName}_sliced.cram"
}

index () {
  ${CMD_SAMTOOLS} index "!{cramOut}"
}

create_cram_slice_cleanup () {
  rm "!{cram.simpleName}_sliced.cram" "!{cram.simpleName}_sliced.cram.crai"
}

main() {  
  create_bed  
  create_cram_slice
  add_replace_read_group
  index
  create_cram_slice_cleanup
}

main "$@"