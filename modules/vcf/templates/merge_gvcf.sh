#!/bin/bash
set -euo pipefail

# workaround for https://github.com/dnanexus-rnd/GLnexus/issues/238
reheader () {
  for gVcf in !{gVcfs}; do
    ${CMD_BCFTOOLS} reheader --fai "!{refSeqFaiPath}" --output "reheadered_${gVcf}" --threads "!{task.cpus}" "${gVcf}"
  done
}

# cannot use --bed because it is broken: https://github.com/dnanexus-rnd/GLnexus/issues/279
merge () {
  local gVcfsReheadered=()
  for gVcf in !{gVcfs}; do
    gVcfsReheadered+=("reheadered_${gVcf}")
  done

  local args=()
  args+=("--dir" "glnexus")
  args+=("--config" "!{config}")
  args+=("--threads" "!{task.cpus}")
  for gVcf in !{gVcfs}; do
    args+=("reheadered_${gVcf}")
  done
  ${CMD_GLNEXUS} "${args[@]}" | ${CMD_BCFTOOLS} view --output-type z --output-file "!{vcfOut}" --no-version --threads "!{task.cpus}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

reheader_cleanup () {
  for gVcf in !{gVcfs}; do
    rm "reheadered_${gVcf}"
  done
}

main () {
  reheader
  merge
  reheader_cleanup
  index
}

main "$@"
