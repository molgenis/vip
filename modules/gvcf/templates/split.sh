#!/bin/bash
set -euo pipefail

main() {
    echo -e "!{bedContent}" > "!{bed}"

    !{CMD_BCFTOOLS} view --regions-file "!{bed}" --output-type z --output-file "!{vcfChunk}" --no-version --threads "!{task.cpus}" "!{vcf}"
    !{CMD_BCFTOOLS} index "!{vcfChunk}"
}

main "$@"
