#!/bin/bash
set -euo pipefail

merge () {
    !{params.CMD_BCFTOOLS} merge --merge none --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" !{vcfs}
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {    
    merge
    index
}

main "$@"
