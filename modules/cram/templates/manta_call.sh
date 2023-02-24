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
	  args+=("--runDir" "${TMPDIR}")

    ${CMD_MANTA} "${args[@]}"
}

run_manta () {
    local args=()
    args+=("${TMPDIR}runWorkflow.py")
    args+=("-j" "!{task.cpus}")

    ${CMD_MANTA} "${args[@]}"

    mv "${TMPDIR}results/variants/diploidSV.vcf.gz" "!{vcfOut}"
    mv "${TMPDIR}results/variants/diploidSV.vcf.gz.tbi" "!{vcfOutIndex}"
}

stats () {
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
    create_bed
    config_manta
    run_manta
    stats
}

main "$@"
