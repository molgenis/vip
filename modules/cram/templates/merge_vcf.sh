#!/bin/bash
set -euo pipefail

merge () {
  local non_empty=()
  local empty=()

  for vcf in !{vcfs}
  do
    ${CMD_BCFTOOLS} index -f "${vcf}" || return 1

    if [[ "$(${CMD_BCFTOOLS} index -n "${vcf}")" -gt 0 ]]
    then
      non_empty+=("${vcf}")
    else
      empty+=("${vcf}")
    fi
  done

  [[ $(( ${#non_empty[@]} + ${#empty[@]} )) -gt 0 ]] || { echo "no input VCFs" >&2; return 1; }

  # if every input is header-only, use the first one as the base (header only)
  local base=()
  if [[ ${#non_empty[@]} -eq 0 ]]
  then
    base=("${empty[0]}")
    empty=("${empty[@]:1}")
  else
    base=("${non_empty[@]}")
  fi

  # samples that have to be appended as all-missing columns
  local extra_samples=()
  local s
  for vcf in "${empty[@]}"
  do
    while IFS= read -r s
    do
      extra_samples+=("${s}")
    done < <(${CMD_BCFTOOLS} query -l "${vcf}")
  done

  local extra_header
  extra_header="$(IFS=$'\t'; echo "${extra_samples[*]}")"

  # step 1: merge the non-empty inputs (or pass through a single one) as plain VCF to stdout
  base_vcf () {
    if [[ ${#base[@]} -eq 1 ]]
    then
      ${CMD_BCFTOOLS} view --output-type v --no-version "${base[0]}"
    else
      ${CMD_BCFTOOLS} merge \
        --merge both \
        --output-type v \
        --no-version \
        --threads "!{task.cpus}" \
        "${base[@]}"
    fi
  }

  # step 2: append the empty inputs' samples ("." = fully missing sample), then compress
  base_vcf \
    | awk -F'\t' -v OFS='\t' -v extra="${extra_header}" -v n="${#extra_samples[@]}" '
        /^##/     { print; next }
        /^#CHROM/ { if (n > 0) { print $0, extra } else { print }; next }
        { line = $0; for (i = 0; i < n; i++) line = line OFS "."; print line }
      ' \
    | ${CMD_BCFTOOLS} view \
        --output-type z \
        --output "!{vcfOut}" \
        --no-version \
        --threads "!{task.cpus}" \
        - \
    || return 1
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {  
  merge
  index
}

main "$@"
