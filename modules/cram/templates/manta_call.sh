#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
  ${CMD_BGZIP} -c "!{bed}" > "!{bedGz}"
  ${CMD_TABIX} "!{bedGz}"
}

config_manta () {
    local args=()
    args+=("/opt/manta/bin/configManta.py")
    args+=("--callRegions" $(realpath "!{bedGz}"))
    args+=("--bam" "!{cram}")
    args+=("--referenceFasta" "!{reference}")
    args+=("--runDir" "$(realpath .)")
    if [ "!{analysisType}" == "WES" ]; then
      args+=("--exome")
    fi

    ${CMD_MANTA} "${args[@]}"
}

run_manta () {
    local args=()
    args+=("$(realpath .)/runWorkflow.py")
    args+=("-j" "!{task.cpus}")

    ${CMD_MANTA} "${args[@]}"
}

reheader_manta_output () {
  ${CMD_BCFTOOLS} query --list-samples "$(realpath .)/results/variants/diploidSV.vcf.gz" > samples.tsv
  local nr_samples=$(wc -l < samples.tsv)
  if [ "$nr_samples" -gt 1 ]; then
    echo -e "Unexpected number of samples in manta ouput, ${nr_samples} instead of 1."
	  exit 1;
  fi
  echo "!{meta.sample.individual_id}" > sample_names.tsv
  ${CMD_BCFTOOLS} reheader --samples sample_names.tsv --output "!{vcfOut}" "$(realpath .)/results/variants/diploidSV.vcf.gz"
}

stats () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    config_manta
    run_manta
    reheader_manta_output
    stats
}

main "$@"
