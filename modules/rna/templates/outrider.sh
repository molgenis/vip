
merge_optimize_output(){
  ${CMD_OUTRIDER} Rscript !{outrider_merge_q_files_script} !{ndimFiles}
}

outrider(){
  echo -e "!{samplesheetContent}" > !{samplesheet}
  sed -i '/^\s*$/d' !{samplesheet}
  ${CMD_OUTRIDER} Rscript "!{outrider_script}" !{outrider_dataset} "merged_q_files.tsv" "!{samplesheet}" "!{outputRds}" "!{outputFile}" "!{assembly}"
}

main() {  
  merge_optimize_output
  outrider
}

main "$@"