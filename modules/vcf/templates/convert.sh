#!/bin/bash
set -euo pipefail

main() {
    !{CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" "!{vcf}"
    !{CMD_BCFTOOLS} index --threads "!{task.cpus}" "!{vcfOut}"
}

main "$@"
