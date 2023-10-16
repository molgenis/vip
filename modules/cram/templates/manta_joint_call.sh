#!/bin/bash
set -euo pipefail

manta_config () {
  local args=()
  args+=("/opt/manta/bin/configManta.py")
  for cram in !{crams}; do
    args+=("--bam" "${cram}")
  done
  
  args+=("--referenceFasta" "!{reference}")
  args+=("--runDir" "$(realpath .)")
  if [ "!{sequencingMethod}" == "WES" ]; then
    args+=("--exome")
  fi

  ${CMD_MANTA} "${args[@]}"
}

manta_run_workflow () {
  local args=()
  args+=("$(realpath .)/runWorkflow.py")
  args+=("-j" "!{task.cpus}")

  ${CMD_MANTA} "${args[@]}"
}

manta () {
  manta_config
  manta_run_workflow
}

post_process () {
  ${CMD_BCFTOOLS} view --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" "results/variants/diploidSV.vcf.gz"
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    manta
    post_process
}

main "$@"
