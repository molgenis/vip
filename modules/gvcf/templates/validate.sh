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

validate_contigs () {
  # collect all reference contigs
  declare -A reference_contigs
  while read -r reference_contig; do
    reference_contigs["${reference_contig}"]="${reference_contig}"
  done < <(cut -f1 "!{referenceFai}")

  # validate that all contigs in input vcf exist in reference
  while read -r vcf_contig; do
    if [[ -z "${reference_contigs[${vcf_contig}]+unset}" ]]; then
      >&2 echo -e "error: input '!{gVcf}' contains contig '${vcf_contig}' that doesn't exist in reference sequence '!{reference}' for assembly '!{assembly}'"
      exit 1
    fi
  done < <(cut -f1 "!{gVcfOutStats}")
}

main () {
  view
  index
  validate_contigs
}

main "$@"
