#!/bin/bash
set -euo pipefail

filter () {
 ${CMD_SAMTOOLS} view -@ "!{task.cpus}" --region-file "!{bed}" --output "!{cramOut}" --no-PG "!{cram}"
}

index () {
  ${CMD_SAMTOOLS} index "!{cramOut}"
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramOutStats}"
}

main() {
  filter
  index
}

main "$@"
