#!/bin/bash
!{CMD_BCFTOOLS} concat \
--output-type z9 \
--output "!{vcf}" \
--no-version \
--threads "!{task.cpus}" !{bcfs}

!{CMD_BCFTOOLS} index "!{vcf}"