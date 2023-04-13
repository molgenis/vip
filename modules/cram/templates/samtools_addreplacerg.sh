#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

create_cram_slice () {
  local args=()
  args+=("view")
  args+=("--cram")
  args+=("--target-file" "!{bed}")
  args+=("--reference" "!{reference}")
  args+=("--no-PG")
  args+=("--threads" "!{task.cpus}")
  args+=("!{cram}")

  local -r tab=$'\t';
  ${CMD_SAMTOOLS} "${args[@]}" | ${CMD_SAMTOOLS} addreplacerg -r "@RG${tab}ID:!{meta.sample.individual_id}${tab}SM:!{meta.sample.individual_id}" -o "!{cramOut}" --threads "!{task.cpus}" -
}

index () {
  ${CMD_SAMTOOLS} index "!{cramOut}"
}

main() {  
  create_bed
  create_cram_slice
  index
}

main "$@"