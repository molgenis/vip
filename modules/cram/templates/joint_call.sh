#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
}

# cannot use --bed because it is broken: https://github.com/dnanexus-rnd/GLnexus/issues/279
create_sliced_vcfs () {
  for gVcf in !{gVcfs}; do
    ${CMD_BCFTOOLS} view --regions-file "!{bed}" --output-type z --output-file "sliced_${gVcf}" --no-version --threads "!{task.cpus}" "${gVcf}"
    ${CMD_BCFTOOLS} index --csi --threads "!{task.cpus}" "sliced_${gVcf}"
  done
}

# workaround for https://github.com/dnanexus-rnd/GLnexus/issues/238
# workaround contains a workaround for https://github.com/samtools/bcftools/issues/1425
reheader () {
  echo -e "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO" > empty.vcf
  ${CMD_BCFTOOLS} reheader --fai "!{refSeqFaiPath}" --threads "!{task.cpus}" empty.vcf | sed '/^##FILTER/d'| sed '/^#CHROM/d' > empty_contigs.vcf

  for gVcf in !{gVcfs}; do
    ${CMD_BCFTOOLS} view -h sliced_${gVcf} | sed '/^##contig/d'| sed '/^##fileformat/d' | cat empty_contigs.vcf - > new_header.vcf
    ${CMD_BCFTOOLS} reheader --header new_header.vcf --threads "!{task.cpus}" sliced_${gVcf} > "reheadered_${gVcf}"
  done
}

# cannot use --bed because it is broken: https://github.com/dnanexus-rnd/GLnexus/issues/279
merge () {
  local args=()
  args+=("--dir" "glnexus")
  args+=("--config" "!{config}")
  args+=("--threads" "!{task.cpus}")
  args+=("--mem-gbytes" "!{task.memory.toGiga() - 1}")
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
  rm "empty_contigs.vcf"
  rm "empty.vcf"
  rm "new_header.vcf"
}

create_sliced_vcfs_cleanup () {
  for gVcf in !{gVcfs}; do
    rm "sliced_${gVcf}"
  done
}

main () {
  create_bed
  create_sliced_vcfs
  reheader
  merge
  reheader_cleanup
  create_sliced_vcfs_cleanup
  index
}

main "$@"
