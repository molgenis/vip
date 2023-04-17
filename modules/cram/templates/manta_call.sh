#!/bin/bash
set -euo pipefail

create_bed () {
  echo -e "!{bedContent}" > "!{bed}"
  !{params.CMD_BGZIP} -c "!{bed}" > "!{bedGz}"
  !{params.CMD_TABIX} "!{bedGz}"
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

    !{params.CMD_MANTA} "${args[@]}"
}

run_manta () {
    local args=()
    args+=("$(realpath .)/runWorkflow.py")
    args+=("-j" "!{task.cpus}")

    !{params.CMD_MANTA} "${args[@]}"

    mv "$(realpath .)/results/variants/diploidSV.vcf.gz" "!{vcfOut}"
}

stats () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    config_manta
    run_manta
    stats
}

main "$@"
