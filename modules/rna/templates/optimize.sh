optimize(){
  ${CMD_OUTRIDER} Rscript !{outrider_optimize_script} !{outriderDataset} "!{qValue}"
}

main() {  
  optimize
}

main "$@"