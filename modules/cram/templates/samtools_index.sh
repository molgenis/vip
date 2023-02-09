#!/bin/bash
set -euo pipefail

main() {
    ${CMD_SAMTOOLS} index "!{cram}"
}

main "$@"
