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
    for cram in !{crams}
    do
      args+=("--bam" $cram)
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

    mv "$(realpath .)/results/variants/diploidSV.vcf.gz" "!{vcfOut}"
}

stats () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    config_manta
    run_manta
    stats
}

main "$@"
