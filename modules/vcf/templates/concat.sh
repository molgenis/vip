#!/bin/bash
set -euo pipefail

main() {
    
    !{CMD_BCFTOOLS} concat \
    --output-type z9 \
    --output "!{vcf}" \
    --no-version \
    --threads "!{task.cpus}" !{vcfs}

    !{CMD_BCFTOOLS} index "!{vcf}"
}

main "$@"
