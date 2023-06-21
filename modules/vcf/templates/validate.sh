#!/bin/bash
set -euo pipefail

create_samples_file () {
  echo -e "!{samplesFileData}" > "sample_names.txt"
}

# the 'view' command serves multiple purposes
# - validating the input bcf/vcf file
# - converting the input bcf/vcf file to a output bgzipped vcf file containing selected samples
view () {
  local args=()
  args+=("--with-header")
  args+=("--no-update")                       # do not (re)calculate INFO fields
  args+=("--samples-file" "sample_names.txt") # file of sample names to include, one sample name per line. the sample order is updated based on file order
  args+=("--compression-level" "1")           # best speed
  args+=("--output-type" "z")                 # compressed VCF
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")                      # do not append version and command line information to the output header
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcf}")
  ${CMD_BCFTOOLS} view "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main () {
  create_samples_file
  view
  index
}

main "$@"
