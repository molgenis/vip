#!/bin/bash
echo -e "!{bedContent}" > "!{bed}"

!{CMD_BCFTOOLS} view --regions-file "!{bed}" --output-type z --output-file "!{gVcfChunk}" --no-version --threads "!{task.cpus}" "!{gVcf}"
!{CMD_BCFTOOLS} index "!{gVcfChunk}"