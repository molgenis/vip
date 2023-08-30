#!/bin/bash
set -euo pipefail

merge () {
  local args=()
  args+=("--merge" "both")            # allow multiallelic SNP and indel records
  args+=("--output-type" "z")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=(!{vcfs})                     # do not double-quote because of multiple values

  ${CMD_BCFTOOLS} merge "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {  
  merge
  index
}

main "$@"
