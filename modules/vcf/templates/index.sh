#!/bin/bash
set -euo pipefail

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcf}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcf}" > "!{vcfOutStats}"
}

main () {
  index
}

main "$@"
