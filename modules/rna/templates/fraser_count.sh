#!/bin/bash
set -euo pipefail

count () {
    echo -e "!{samplesheetContent}" > !{samplesheet}
    sed -i '/^\s*$/d' !{samplesheet}
    mkdir !{fraser_output}
    ${CMD_OUTRIDER} bash -c 'Rscript !{fraser_counts_script} !{samplesheet} !{fraser_output}'
}

merge () {
    ${CMD_OUTRIDER} bash -c 'Rscript !{fraser_merge_counts_script} "!{fraser_output}" "!{externalCounts}" !{externalCountsAmount}'
}

main() {  
  count
  merge
}

main "$@"