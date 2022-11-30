#!/bin/bash
!{CMD_DEEPTRIO} \
--model_type=!{meta.sample.seq_method} \
--ref=!{reference} \
--reads_child=!{cramChild} \
--reads_parent1=!{cramFather} \
--reads_parent2=!{cramMother} \
--regions !{meta.contig} \
--sample_name_child=!{meta.sample.family_id}_!{meta.sample.individual_id} \
--sample_name_parent1=!{meta.sample.family_id}_!{meta.sample.paternal_id} \
--sample_name_parent2=!{meta.sample.family_id}_!{meta.sample.maternal_id} \
--output_vcf_child="!{vcfChild}" \
--output_vcf_parent1="!{vcfFather}" \
--output_vcf_parent2="!{vcfMother}" \
--output_gvcf_child="!{gVcfChild}" \
--output_gvcf_parent1="!{gVcfFather}" \
--output_gvcf_parent2="!{gVcfMother}" \
--intermediate_results_dir !{TMPDIR} \
--num_shards=!{task.cpus}