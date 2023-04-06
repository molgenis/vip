#!/bin/bash
set -euo pipefail

# workaround for https://github.com/dnanexus-rnd/GLnexus/issues/238
# workaround contains a workaround for https://github.com/samtools/bcftools/issues/1425
reheader () {
  echo -e "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO" > empty.vcf
  ${CMD_BCFTOOLS} reheader --fai "!{refSeqFaiPath}" --output "empty_contigs.vcf" --threads "!{task.cpus}" empty.vcf


  for gVcf in !{gVcfs}; do
    ${CMD_BCFTOOLS} merge --output-type z --output "reheadered_${gVcf}" --no-version --threads "!{task.cpus}" empty_contigs.vcf "${gVcf}"
  done
}

# cannot use --bed because it is broken: https://github.com/dnanexus-rnd/GLnexus/issues/279
merge () {
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
  #reheader_cleanup
  index
}

main "$@"
