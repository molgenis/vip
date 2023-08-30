#!/bin/bash
set -euo pipefail

main() {
    cat !{fastq_r1s} > "!{fastq_r1}"
    cat !{fastq_r2s} > "!{fastq_r2}"
}

main "$@"
