#!/bin/bash
set -euo pipefail

create_ped () {
  echo -e "!{pedigreeContent}" > "!{pedigree}"
}

inheritance () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-inheritance-matcher/lib/vcf-inheritance-matcher.jar")
  args+=("--input" "!{vcf}")
  args+=("--output" "!{vcfOut}")
  if [ -n "!{pedigree}" ]; then
    args+=("--pedigree" "!{pedigree}")
  fi
  if [ -n "!{probands}" ]; then
    args+=("--probands" "!{probands}")
  fi

  ${CMD_VCFINHERITANCEMATCHER} java "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  create_ped
  inheritance
  index
}

main "$@"