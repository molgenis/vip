#!/bin/bash
set -euo pipefail

concat () {
  printf "##VIP_Version=%s\n##VIP_Command=%s" "${VIP_VERSION}" "!{workflow.commandLine}" > "!{basename}.header"

  local args=()
  args+=("annotate")
  args+=("--header-lines" "!{basename}.header")
  args+=("--output-type" "z9")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("-")

  !{CMD_BCFTOOLS} concat --no-version --threads "!{task.cpus}" !{vcfs} | !{CMD_BCFTOOLS} "${args[@]}"
}

index () {
  !{CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
}

main() {  
  concat
  index
}

main "$@"
