#!/bin/bash
set -euo pipefail

merge () {
 ${CMD_OUTRIDER} bash -c 'Rscript ${RNA}/nextflow/outrider/mergecounts.R !{counts}'
}

create_dataset () {
echo -e "!{samplesheetContent}" > !{samplesheet}
sed -i '/^\s*$/d' !{samplesheet}
#FIXME
 ${CMD_OUTRIDER2} bash -c 'Rscript /groups/umcg-gcc/tmp02/projects/vipt/umcg-bcharbon/rna/Rscripts/createDataSet.R merged_outrider_counts.txt "!{samplesheet}" "!{externalCounts}" !{externalCountsAmount}'
}

optimize(){
  output_files=()

  #FIXME: separate process to allow parallel processing?
  while IFS= read -r q_value; do
    # FIXME
    ${CMD_OUTRIDER2} Rscript /groups/umcg-gcc/tmp02/projects/vipt/umcg-bcharbon/rna/Rscripts/optimize.R outrider.rds "${q_value}"
    output_files+=("${q_value}.tsv")
  done < "q_values.txt"
}
merge_optimize_output(){
  inputFiles="${output_files[*]}"
  echo -e "FIXME"
  #FIXME
  #Rscript ${params.outrider.mergeQFiles} ${inputFiles}
}

outrider(){
  echo -e "FIXME"
  #Rscript ${params.outrider.outriderR} "${outriderDataset}" "${qfile}" "${samplesheet}" "final_outrider.rds" "result_table_outrider.tsv" "${params.genomeReferenceBuild}"
}

main() {  
  merge
  create_dataset
  optimize
  merge_optimize_output
  outrider
}

main "$@"