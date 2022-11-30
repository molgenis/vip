#!/bin/bash
!{CMD_BCFTOOLS} view --regions "!{meta.contig}" --output-type z --output-file "!{gVcfContig}" --no-version --threads "!{task.cpus}" "!{gVcf}"