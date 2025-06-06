#!/bin/bash
set -euo pipefail

count () {
    echo -e "!{samplesheetContent}" > !{samplesheet}
    sed -i '/^\s*$/d' !{samplesheet}
    mkdir !{fraser_output}
    ${CMD_OUTRIDER} bash -c 'Rscript !{fraser_count_script} !{samplesheet} !{fraser_output}'
}

merge () {
    echo -e "!{samplesheetContent}" > !{samplesheet}
    sed -i '/^\s*$/d' !{samplesheet}
    ${CMD_OUTRIDER} bash -c 'Rscript !{fraser_merge_counts_script} "!{fraser_output}" "!{externalCounts}" !{externalCountsAmount}'
}

main() {  
  count
  merge
}

main "$@"