#!/bin/bash
${CMD_BCFTOOLS} concat \
--output-type z9 \
--output "${gVcf}" \
--no-version \
--threads "${task.cpus}" ${gVcfs}

${CMD_BCFTOOLS} index "${gVcf}"