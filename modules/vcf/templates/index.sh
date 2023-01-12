#!/bin/bash
set -euo pipefail

index () {
  !{CMD_BCFTOOLS} index --csi --output "!{vcfIndex}" --threads "!{task.cpus}" "!{vcf}"
}

main () {
  index
}

main "$@"
