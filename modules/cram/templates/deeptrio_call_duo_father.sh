#!/bin/bash
set -euo pipefail

main() {
    echo -e "!{bedContent}" > "!{bed}"
    
    ${CMD_DEEPTRIO} \
    --model_type="!{params.sequencingMethod}" \
    --ref="!{reference}" \
    --regions "!{bed}" \
    --reads_child="!{cramChild}" \
    --reads_parent1="!{cramFather}" \
    --sample_name_child="!{meta.samples.proband.individual_id}" \
    --sample_name_parent1="!{meta.samples.proband.paternal_id}" \
    --output_vcf_child="!{vcfChild}" \
    --output_vcf_parent1="!{vcfFather}" \
    --output_gvcf_child="!{gVcfChild}" \
    --output_gvcf_parent1="!{gVcfFather}" \
    --intermediate_results_dir "." \
    --num_shards="!{task.cpus}"
}

main "$@"
