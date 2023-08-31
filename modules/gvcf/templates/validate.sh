#!/bin/bash
set -euo pipefail

# the 'view' command serves multiple purposes
# - validating the input bcf/vcf file
# - converting the input bcf/vcf file to a output bgzipped vcf
view () {
  local args=()
  args+=("--with-header")
  args+=("--no-update")                       # do not (re)calculate INFO fields
  args+=("--samples" "!{sampleId}")           # sample to include
  args+=("--compression-level" "1")           # best speed
  args+=("--output-type" "z")                 # compressed VCF
  args+=("--output" "!{gVcfOut}")
  args+=("--no-version")                      # do not append version and command line information to the output header
  args+=("--threads" "!{task.cpus}")
  args+=("!{gVcf}")

  ${CMD_BCFTOOLS} view "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{gVcfOutIndex}" --threads "!{task.cpus}" "!{gVcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{gVcfOut}" > "!{gVcfOutStats}"
}

main () {
  view
  index
}

main "$@"
