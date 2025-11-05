#!/bin/bash
set -euo pipefail

count () {
 ${CMD_OUTRIDER} bash -c 'Rscript !{outrider_counts_script} !{sampleName} !{bam} !{params.rna.genes_gtf} !{pairedEnd} !{strandSpecific}'
}

main() {  
  count
}

main "$@"