#!/bin/bash
set -euo pipefail

stats () {
  !{CMD_BCFTOOLS} index --stats "!{vcf}" > "!{vcfOutStats}"
}

main () {
  stats
}

main "$@"
