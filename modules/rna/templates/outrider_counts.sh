#!/bin/bash
set -euo pipefail

count () {
 ${CMD_OUTRIDER} bash -c 'Rscript ${RNA}/nextflow/outrider/featurecounts.R !{sampleName} !{bam} !{params.rna.genes_gtf} !{pairedEnd} !{strandSpecific}'
}

main() {  
  count
}

main "$@"