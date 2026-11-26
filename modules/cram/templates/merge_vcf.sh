#!/bin/bash
set -euo pipefail

merge () {
  local inputs=()

  for vcf in !{vcfs}
  do
    ${CMD_BCFTOOLS} index -f "${vcf}" || return 1
    inputs+=("${vcf}")
  done

  [[ ${#inputs[@]} -gt 0 ]] || { echo "no input VCFs" >&2; return 1; }

  if [[ ${#inputs[@]} -eq 1 ]]
  then
    # nothing to merge: pass the single input through
    ${CMD_BCFTOOLS} view \
      --output-type z \
      --output "!{vcfOut}" \
      --no-version \
      "${inputs[0]}"
  else
    local args=()
    args+=("--merge" "both")          # allow multiallelic SNP and indel records
    args+=("--output-type" "z")
    args+=("--output" "!{vcfOut}")
    args+=("--no-version")
    args+=("--threads" "!{task.cpus}")

    ${CMD_BCFTOOLS} merge "${args[@]}" "${inputs[@]}"
  fi
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
