#!/bin/bash
set -euo pipefail

main() {
    count=!{CMD_BCFTOOLS} index -n "!{vcfIndex}"
}

main "$@"
