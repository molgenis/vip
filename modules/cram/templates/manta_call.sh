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
    local -a cram_array=(!{crams})
    for (( i=0; i<${#cram_array[@]}; i++ ));
    do
      cram="${cram_array["${i}"]}"
      args+=("--bam" "$cram")
    done
    args+=("--referenceFasta" "!{reference}")
    args+=("--runDir" "$(realpath .)")
    if [ "!{sequencingMethod}" == "WES" ]; then
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

# workaround for https://github.com/Ensembl/ensembl-vep/issues/1414
filter_manta () {
  ${CMD_BCFTOOLS} view -i 'FILTER="PASS"|FILTER="."' --output-type z --output "!{vcfOut}" --no-version --threads "!{task.cpus}" "results/variants/diploidSV.vcf.gz"
}

stats () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    config_manta
    run_manta
    # workaround for https://github.com/Ensembl/ensembl-vep/issues/1414
    filter_manta
    stats
}

main "$@"
