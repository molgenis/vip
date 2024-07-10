#!/bin/bash
set -euo pipefail

filter () {
 ${CMD_SAMTOOLS} view -@ "!{task.cpus}" --region-file "!{bed}" --output "!{cramOut}" --no-PG --write-index "!{cram}"
}

stats () {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  filter
  stats
}

main "$@"
