#!/bin/bash
set -euo pipefail

concat () {
    ${CMD_BCFTOOLS} concat --allow-overlaps --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" !{vcfs}
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {    
    concat
    index
}

main "$@"