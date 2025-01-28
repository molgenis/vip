#!/bin/bash
set -euo pipefail

create_ped () {
  echo -e "!{pedigreeContent}" > "!{pedigree}"
}

filter_bams () {
  # filter all reads without readgroups
  count=$(${CMD_BCFTOOLS} query -l "!{vcf}" | wc -l)
  if [ "${count}" -gt 1 ]; then
    for cram in !{crams}; do
        ${CMD_SAMTOOLS} view -h ${cram} | awk 'substr($0, 1, 1) == "@" || $0 ~ /RG:Z:/' | ${CMD_SAMTOOLS} view -b > "${cram}_filtered.bam"
        ${CMD_SAMTOOLS} index "${cram}_filtered.bam"
    done
  fi
}

phase_variants () {
      local args=()
      local cramAdded=false
      args+=("--reference" "!{paramReference}" )
      args+=("--output" "!{vcfOut}")
      args+=("!{vcf}")
      # use filtered cram files if multiple samples are present
      sampleCount=$(${CMD_BCFTOOLS} query -l "!{vcf}" | wc -l)
      if [ "${sampleCount}" -gt 1 ]; then
        for cram in !{crams}; do
            count=$(${CMD_SAMTOOLS} view -c "${cram}_filtered.bam")
            if [ "${count}" -gt 0 ]; then
              #do not run Whatshap if no crams remain
              cramAdded="true"
              args+=("${cram}_filtered.bam")
            fi
        done
        args+=("--ped" "!{pedigree}") 
      # assume all reads belong to the sample if only one sample is present
      else
        cramAdded="true"
        args+=("!{crams}")
        args+=("--ignore-read-groups")
      fi
      args+=("--algorithm" "!{algorithm}")
      args+=("--internal-downsampling" "!{internalDownsampling}")
      args+=("--mapping-quality" "!{mappingQuality}")
      args+=("--error-rate" "!{errorRate}")
      args+=("--maximum-error-rate" "!{maximumErrorRate}")
      args+=("--threshold" "!{threshold}")
      args+=("--negative-threshold" "!{negativeThreshold}")
      args+=("--default-gq" "!{defaultGq}")
      args+=("--recombrate" "!{recombrate}")
      #args+=("--supplementary-distance" "!{supplementaryDistance}") #disabled because of https://github.com/whatshap/whatshap/issues/579
      if [ -n "!{glRegularizer}" ]; then
        args+=("--gl-regularizer" "!{glRegularizer}")
      fi
      if [ -n "!{changedGenotypeList}" ]; then
        args+=("--changed-genotype-list" "!{changedGenotypeList}")
      fi
      if [ -n "!{recombinationList}" ]; then
        args+=("--recombination-list" "!{recombinationList}")
      fi
      if [ -n "!{genmap}" ]; then
        args+=("--genmap" "!{genmap}")
      fi
      if [ -n "!{outputReadList}" ]; then
        args+=("--output-read-list" "!{outputReadList}")
      fi
      if [[ "!{onlySnvs}" == "true" ]]; then
        args+=("--only-snvs" "!{onlySnvs}")
      fi
      if [[ "!{distrustGenotypes}" == "true" ]]; then
        args+=("--distrust-genotypes")
      fi
      if [[ "!{includeHomozygous}" == "true" ]]; then
        args+=("--include-homozygous")
      fi
      if [[ "!{noGeneticHaplotyping}" == "true" ]]; then
        args+=("--no-genetic-haplotyping")
      fi
      if [[ "!{usePedSamples}" == "true" ]]; then
        args+=("--use-ped-samples")
      fi
      if [[ "!{useSupplementary}" == "true" ]]; then
        args+=("--use-supplementary")
      fi

      if [ "${cramAdded}" == "true" ]; then
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
    if [ -f "${cram}_filtered.bam" ] ; then
        rm ${cram}_filtered.bam
        rm ${cram}_filtered.bam.bai
      fi
  done
}

main() {
    create_ped
    filter_bams
    phase_variants
    index
    cleanup
}

main "$@"