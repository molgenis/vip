#!/bin/bash
set -euo pipefail

link () {
    cp --link "!{vcf}" "!{vcfOut}"
    cp --link "!{vcfIndex}" "!{vcfOutIndex}"
    cp --link "!{vcfStats}" "!{vcfOutStats}"
}

main() {  
  link
}

main "$@"