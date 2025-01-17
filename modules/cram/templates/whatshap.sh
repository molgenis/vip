#!/bin/bash
set -euo pipefail

create_ped () {
  echo -e "!{pedigreeContent}" > "!{pedigree}"
}

filter_bams () {
  # filter all reads without readgroups
    for cram in !{crams}; do
        ${CMD_SAMTOOLS} view -h ${cram} | awk 'substr($0, 1, 1) == "@" || $0 ~ /RG:Z:/' | ${CMD_SAMTOOLS} view -b > "${cram}_filtered.bam"
        ${CMD_SAMTOOLS} index "${cram}_filtered.bam"
    done
}

phase_variants () {
      local args=()
      local cramAdded=false

      args+=("--ped" "!{pedigree}") 
      args+=("--reference" "!{paramReference}" )
      args+=("--output" "!{vcfOut}")
      args+=("!{vcf}")
      for cram in !{crams}; do
          count=$(${CMD_SAMTOOLS} view -c "${cram}_filtered.bam")
          if [ "${count}" -gt 0 ]; then
            cramAdded="true"
            args+=("${cram}_filtered.bam")
          fi
      done
      if [ "${cramAdded}" eq "true" ]; then
        ${CMD_WHATSHAP} "${args[@]}"
      else
        #skip phasing if there are no suitable crams
        cp "!{vcf}" "!{vcfOut}"
      fi
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

cleanup () {
    for cram in !{crams}; do
        rm ${cram}_filtered.bam
        rm ${cram}_filtered.bam.bai
    done
}

main() {
    create_ped
    filter_bams
    phase_variants
    index
    #cleanup
}

main "$@"