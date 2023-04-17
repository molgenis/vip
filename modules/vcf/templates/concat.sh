#!/bin/bash
set -euo pipefail

concat () {
  local args=()
  args+=("concat")
  args+=("--output-type" "z")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")

  !{params.CMD_BCFTOOLS} "${args[@]}" !{vcfs}
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {  
  concat
  index
}

main "$@"
