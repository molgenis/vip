#!/bin/bash
set -euo pipefail

main() {
    cat !{fastqs} > "!{fastq}"
}

main "$@"
