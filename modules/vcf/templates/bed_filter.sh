#!/bin/bash
set -euo pipefail

filter () {
  ${CMD_BCFTOOLS} view --region-file "!{bed}" --output-type z -output "!{vcfOut}" "!{vcf}" 
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
