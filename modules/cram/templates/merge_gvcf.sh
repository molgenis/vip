#!/bin/bash
set -euo pipefail

merge () {
  local args=()
  args+=("--dir" "glnexus")
  args+=("--config" "!{config}")
  args+=("--threads" "!{task.cpus}")
  ${CMD_GLNEXUS} "${args[@]}" !{gVcfs} | ${CMD_BCFTOOLS} view --output-type z --output-file "unordered_!{vcfOut}" --no-version --threads "!{task.cpus}"
}

order_samples () {
  ${CMD_BCFTOOLS} query -l "unordered_!{vcfOut}" | sort > samples.txt
  ${CMD_BCFTOOLS} view -O z -S samples.txt "unordered_!{vcfOut}" > !{vcfOut}
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main () {
  merge
  order_samples
  index
}

main "$@"
