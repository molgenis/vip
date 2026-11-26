#!/bin/bash
set -euo pipefail

concat () {
  local non_empty_vcfs=()
  local first=""

  for vcf in !{vcfs}
  do
    local f="sorted_${vcf}"
    [[ -z "${first}" ]] && first="${f}"

    ${CMD_BCFTOOLS} index -f "${f}" || return 1

    # index -n prints the number of records
    if [[ "$(${CMD_BCFTOOLS} index -n "${f}")" -gt 0 ]]
    then
      non_empty_vcfs+=("${f}")
    fi
  done

  [[ -n "${first}" ]] || { echo "no input VCFs" >&2; return 1; }

  if [[ ${#non_empty_vcfs[@]} -eq 0 ]]
  then
    # all inputs are header-only: pass the first one through
    ${CMD_BCFTOOLS} view \
      --output-type z \
      --output "unsorted_!{vcfOut}" \
      --no-version \
      "${first}"
  elif [[ ${#non_empty_vcfs[@]} -eq 1 ]]
  then
    # nothing to concatenate
    ${CMD_BCFTOOLS} view \
      --output-type z \
      --output "unsorted_!{vcfOut}" \
      --no-version \
      "${non_empty_vcfs[0]}"
  else
    ${CMD_BCFTOOLS} concat \
      --allow-overlaps \
      --remove-duplicates \
      --output-type z \
      --output "unsorted_!{vcfOut}" \
      --no-version \
      --threads "!{task.cpus}" \
      "${non_empty_vcfs[@]}"
  fi
}

bcftools_sort () {
  ${CMD_BCFTOOLS} norm --do-not-normalize --rm-dup exact --no-version --threads "!{task.cpus}" "unsorted_!{vcfOut}" | ${CMD_BCFTOOLS} sort --temp-dir . --max-mem "!{(task.memory.toMega() * 0.75).intValue()}M" --output-type z --output "!{vcfOut}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

order_samples () {
  local -a vcf_array=(!{vcfs})
  for (( i=0; i<${#vcf_array[@]}; i++ ));
  do
    vcf="${vcf_array["${i}"]}"
    ${CMD_BCFTOOLS} query --list-samples "${vcf}" | sort > sorted_samples.txt
    ${CMD_BCFTOOLS} view --no-version --threads "!{task.cpus}" --output-type z --samples-file "sorted_samples.txt" "${vcf}" > "sorted_${vcf}" 
    ${CMD_BCFTOOLS} index --csi --output "sorted_${vcf}.csi" --threads "!{task.cpus}" "sorted_${vcf}"
  done
}

main() {  
  order_samples
  concat
  bcftools_sort
  index
}

main "$@"