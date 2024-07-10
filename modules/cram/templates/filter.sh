#!/bin/bash
set -euo pipefail

filter () {
 #FIXME: ${CMD_SAMTOOLS} view -@ "!{task.cpus}" --no-PG --write-index "!{cram}" "!{cramOut}"
}

stats () {
  ${CMD_SAMTOOLS} idxstats "!{cram}" > "!{cramStats}"
}

main() {
  filter
  stats
}

main "$@"
