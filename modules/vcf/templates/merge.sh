#!/bin/bash
set -euo pipefail

main() {    
    !{CMD_BCFTOOLS} merge --merge none --output-type z --output "!{vcf}" --no-version --threads "!{task.cpus}" !{vcfs}
    !{CMD_BCFTOOLS} index --threads "!{task.cpus}" "!{vcf}"
}

main "$@"
