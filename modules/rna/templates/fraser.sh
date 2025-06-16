#!/bin/bash
set -euo pipefail

fraser () {
  echo -e "!{samplesheetContent}" > !{samplesheet}
  sed -i '/^\s*$/d' !{samplesheet}
  ${CMD_OUTRIDER} bash -c 'Rscript !{fraser_script} !{samplesheet} !{output} !{refSeqPath}'
}

main() {  
  fraser
}

main "$@"