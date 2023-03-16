#!/bin/bash
set -euo pipefail

concat () {
  local args=()
  args+=("concat")
  args+=("--allow-overlaps")
  args+=("--remove-duplicates")
  args+=("--output-type" "z")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=(!{vcfs})

  ${CMD_BCFTOOLS} "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {    
  concat
  index
}

main "$@"