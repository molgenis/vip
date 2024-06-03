#!/bin/bash
set -euo pipefail

coverage () {
  ${CMD_SAMTOOLS} coverage --reference "!{paramReference}" "!{cram}" | gzip "!{cramCoverageOut}"
}

depth () {
  ${CMD_SAMTOOLS} depth --reference "!{paramReference}" "!{cram}" | gzip > "!{cramDepthOut}"
}

main() {
  coverage
  depth
}

main "$@"
