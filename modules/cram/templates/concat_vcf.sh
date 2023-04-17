#!/bin/bash
set -euo pipefail

concat () {
  local args=()
  args+=("concat")
  args+=("--allow-overlaps")
  args+=("--remove-duplicates")
  args+=("--output-type" "z")
  args+=("--output" "unsorted_!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  for vcf in !{vcfs}
  do
    args+=("sorted_${vcf}")
  done

  !{params.CMD_BCFTOOLS} "${args[@]}"
}

bcftools_sort () {
  !{params.CMD_BCFTOOLS} sort --output-type z "unsorted_!{vcfOut}" --output "!{vcfOut}"
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

order_samples () {
  local -a vcf_array=(!{vcfs})
  for (( i=0; i<${#vcf_array[@]}; i++ ));
  do
    vcf="${vcf_array["${i}"]}"
    !{params.CMD_BCFTOOLS} query --list-samples "${vcf}" | sort > sorted_samples.txt
    !{params.CMD_BCFTOOLS} view --no-version --threads "!{task.cpus}" --output-type z --samples-file "sorted_samples.txt" "${vcf}" > "sorted_${vcf}"
    !{params.CMD_BCFTOOLS} index --csi --output "sorted_${vcf}.csi" --threads "!{task.cpus}" "sorted_${vcf}"
  done
}

main() {    
  order_samples
  concat
  bcftools_sort
  index
}

main "$@"