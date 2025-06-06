#!/bin/bash
set -euo pipefail

fraser () {
 ${CMD_OUTRIDER} bash -c 'Rscript !{fraser_script} !{sampleName} !{bam} !{params.rna.genes_gtf} !{pairedEnd} !{strandSpecific}'
}

main() {  
  fraser
}

main "$@"