
merge_merge_q_files(){
  ${CMD_OUTRIDER} Rscript !{outrider_merge_q_files_script} !{ndimFiles}
}

main() {  
  merge_merge_q_files
}

main "$@"