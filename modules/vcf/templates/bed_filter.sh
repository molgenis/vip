#!/bin/bash
set -euo pipefail

filter () {
  #FIXME: ${CMD_BCFTOOLS} view "!{vcf}" > "!{vcfOut}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  filter
  index
}

main "$@"
