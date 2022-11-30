#!/bin/bash
echo -e "!{bedContent}" > "!{bed}"
    
!{CMD_DEEPVARIANT} \
--model_type=!{meta.sample.seq_method} \
--ref=!{reference} \
--reads=!{cram} \
--regions !{bed} \
--sample_name !{meta.sample.family_id}_!{meta.sample.individual_id} \
--output_vcf="!{vcf}" \
--output_gvcf="!{gVcf}" \
--intermediate_results_dir . \
--num_shards=!{task.cpus}