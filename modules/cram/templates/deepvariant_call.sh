#!/bin/bash
set -euo pipefail

main() {
    echo -e "!{bedContent}" > "!{bed}"
        
    !{CMD_DEEPVARIANT} \
    --model_type="!{params.sequencingMethod}" \
    --ref="!{reference}" \
    --reads="!{cram}" \
    --regions "!{bed}" \
    --sample_name "!{meta.sample.individual_id}" \
    --output_vcf="!{vcf}" \
    --output_gvcf="!{gVcf}" \
    --intermediate_results_dir . \
    --num_shards="!{task.cpus}"
}

main "$@"
