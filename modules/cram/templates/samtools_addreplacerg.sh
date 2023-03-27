#!/bin/bash
set -euo pipefail

addReplaceReadGroup () {
  tab=$'\t';
  ${CMD_SAMTOOLS} addreplacerg -r "@RG${tab}ID:!{meta.sample.individual_id}${tab}SM:!{meta.sample.individual_id}" -o "!{cramOut}" --threads !{task.cpus} !{cram}
}

index () {
  ${CMD_SAMTOOLS} index "!{cramOut}"
}

main() {    
  addReplaceReadGroup
  index
}

main "$@"