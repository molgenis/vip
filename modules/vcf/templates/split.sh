#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

create_region () {
  !{params.CMD_BCFTOOLS} view --regions-file "!{bed}" --output-type z --output-file "!{vcfOut}" --no-version --threads "!{task.cpus}" "!{vcf}"
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  create_bed    
  create_region
  index
}

main "$@"
