#!/bin/bash
set -euo pipefail

link () {
    cp "!{vcf}" "!{vcfOut}"
    cp "!{vcfIndex}" "!{vcfOutIndex}"
    cp "!{vcfStats}" "!{vcfOutStats}"
}

main() {  
  link
}

main "$@"