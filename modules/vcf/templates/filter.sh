#!/bin/bash
set -euo pipefail

filter () {
  args+=("-i" "!{vcf}")

  local operator;
  if [[ "!{classes}" =~ .+,.+ ]]; then
    args+=("-f" "VIPC in !{classes}")
  else
    args+=("-f" "VIPC is !{classes}")
  fi
  if [ "!{consequences}" = true ]; then
    args+=("--only_matched")
  fi

  !{params.CMD_FILTERVEP} filter_vep "${args[@]}"  | !{params.CMD_BGZIP} -c > "!{vcfOut}"
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  filter
  index
}

main "$@"
