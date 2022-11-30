#!/bin/bash
!{CMD_GLNEXUS} \
    --dir !{TMPDIR}/glnexus \
    --config DeepVariantWGS \
    --threads !{task.cpus} \
    !{gVcfs} | \
    !{CMD_BCFTOOLS} view --output-type z --output-file !{vcf} --no-version --threads "!{task.cpus}"

!{CMD_BCFTOOLS} index --threads "!{task.cpus}" !{vcf}