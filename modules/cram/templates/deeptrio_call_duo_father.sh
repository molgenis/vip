#!/bin/bash
set -euo pipefail

main() {
    !{CMD_DEEPTRIO} \
    --model_type="!{params.sequencingMethod}" \
    --ref="!{reference}" \
    --reads_child="!{cramChild}" \
    --reads_parent1="!{cramFather}" \
    --regions "!{meta.contig}" \
    --sample_name_child="!{meta.sample.individual_id}" \
    --sample_name_parent1="!{meta.sample.paternal_id}" \
    --output_vcf_child="!{vcfChild}" \
    --output_vcf_parent1="!{vcfFather}" \
    --output_gvcf_child="!{gVcfChild}" \
    --output_gvcf_parent1="!{gVcfFather}" \
    --intermediate_results_dir "!{TMPDIR}" \
    --num_shards="!{task.cpus}"
}

main "$@"