#!/bin/bash
set -euo pipefail

filter_samples () {
  local args=()
  args+=("filter")
  args+=("--include" "!{params.vcf.filter_samples.classes.split(',').collect(it -> "INFO/VIPC_S==\\\"" + it + "\\\"").join('||')}")
  args+=("--output" "!{vcfOut}")
  args+=("--output-type" "z")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcf}")

  !{params.CMD_BCFTOOLS} "${args[@]}"
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  filter_samples
  index
}

main "$@"