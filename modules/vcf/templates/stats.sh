#!/bin/bash
set -euo pipefail

stats () {
  !{params.CMD_BCFTOOLS} index --stats "!{vcf}" > "!{vcfOutStats}"
}

main () {
  stats
}

main "$@"
