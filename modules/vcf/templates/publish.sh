#!/bin/bash
set -euo pipefail

concat () {
  local args=()
  args+=("concat")
  args+=("--output-type" "z9")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")

  !{params.CMD_BCFTOOLS} "${args[@]}" !{vcfs}
}

view () {
  local args=()
  args+=("view")
  args+=("--output-type" "z9")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")

  !{params.CMD_BCFTOOLS} "${args[@]}" "!{vcfs.first()}"
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
}

main() {
  if [[ "!{vcfs.size()}" -gt "1" ]]; then
    concat
  else
    view
  fi

  index
}

main "$@"
