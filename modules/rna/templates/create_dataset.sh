#!/bin/bash
set -euo pipefail

merge () {
  ${CMD_OUTRIDER} bash -c 'Rscript !{outrider_merge_counts_script} !{counts}'
}

create_dataset () {
  echo -e "!{samplesheetContent}" > !{samplesheet}
  sed -i '/^\s*$/d' !{samplesheet}
  ${CMD_OUTRIDER} bash -c 'Rscript !{outrider_create_dataset_script} merged_outrider_counts.txt "!{samplesheet}" "!{externalCounts}" !{externalCountsAmount} /groups/umcg-gcc/tmp02/projects/vipt/umcg-bcharbon/rna/gencode.v29.annotation.gtf.gz'
  mv q_values.txt !{qvalues}
}

main() {  
  merge
  create_dataset
}

main "$@"