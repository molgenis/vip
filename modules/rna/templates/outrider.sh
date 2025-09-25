outrider(){
  echo -e "!{samplesheetContent}" > !{samplesheet}
  sed -i '/^\s*$/d' !{samplesheet}
  ${CMD_OUTRIDER} Rscript "!{outrider_script}" "!{outrider_dataset}" "!{merged_q_files}" "!{samplesheet}" "!{outputRds}" "!{outputFile}" "!{assembly}"
}

main() {  
  outrider
}

main "$@"