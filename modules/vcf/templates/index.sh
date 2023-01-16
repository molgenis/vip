#!/bin/bash
set -euo pipefail

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcf}"
  ${CMD_BCFTOOLS} index --stats "!{vcf}" > "!{vcfOutStats}"
}

main () {
  index
}

main "$@"
