#!/bin/bash
set -euo pipefail

concat () {
  local args=()
  args+=("concat")
  args+=("--output-type" "z9")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")

  ${CMD_BCFTOOLS} "${args[@]}" !{vcfs}
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
}

main() {
  concat
  index
}

main "$@"
