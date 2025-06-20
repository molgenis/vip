
merge_optimize_output(){
  ${CMD_OUTRIDER} Rscript !{outrider_merge_q_files_script} !{ndimFiles}
}

outrider(){
  echo -e "!{samplesheetContent}" > !{samplesheet}
  sed -i '/^\s*$/d' !{samplesheet}
  #FIXME: why is this process never cached?
  #${CMD_OUTRIDER} Rscript "!{outrider_script}" !{outrider_dataset} "merged_q_files.tsv" "!{samplesheet}" "!{outputRds}" "!{outputFile}" "!{assembly}"

  cp "/groups/umcg-gcc/tmp02/projects/vipt/umcg-bcharbon/rna_test/output/intermediates/combined_samples_outrider_output.tsv" "!{fullOutputFile}"
}

main() {  
  merge_optimize_output
  outrider
}

main "$@"