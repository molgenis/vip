#!/bin/bash
set -euo pipefail

main() {
    !{params.CMD_SAMTOOLS} index "!{cram}"
}

main "$@"
