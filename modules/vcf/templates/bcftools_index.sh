#!/bin/bash
set -euo pipefail

main() {
    !{CMD_BCFTOOLS} index --threads "!{task.cpus}" "!{vcf}"
}

main "$@"
