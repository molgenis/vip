#!/bin/bash
set -euo pipefail

main() {
    !{CMD_MINIMAP2} -t "!{task.cpus}"  -d "!{fasta_mmi}" "!{reference}"
}

main "$@"