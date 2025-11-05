#!/bin/bash
set -euo pipefail

fraser () {
  echo -e "!{samplesheetContent}" > !{samplesheet}
  sed -i '/^\s*$/d' !{samplesheet}
  ${CMD_OUTRIDER} bash -c 'Rscript !{fraser_script} !{samplesheet} !{output} !{refSeqPath}'
  mv "combined_samples_result_table_fraser.tsv" "!{outputFile}"
}

main() {  
  fraser
}

main "$@"