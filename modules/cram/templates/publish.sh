#!/bin/bash
set -euo pipefail

concat () {
  local args=()
  args+=("concat")
  args+=("--output-type" "z9")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  for vcf in !{vcfs}
  do
    args+=("sorted_${vcf}")
  done

  ${CMD_BCFTOOLS} "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
}

order_samples () {
  local -a vcf_array=(!{vcfs})
  for (( i=0; i<${#vcf_array[@]}; i++ ));
  do
    vcf=${vcf_array[$i]}
    ${CMD_BCFTOOLS} query -l ${vcf} | sort > sorted_samples.txt
    ${CMD_BCFTOOLS} view -O z -S "sorted_samples.txt" ${vcf} > "sorted_${vcf}" 
    ${CMD_BCFTOOLS} index --csi --output "sorted_${vcf}.csi" --threads "!{task.cpus}" "sorted_${vcf}"
  done
}

main() {
  order_samples
  concat
  index
}

main "$@"
