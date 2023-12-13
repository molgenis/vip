gado_process() {
  echo -e -n "all_samples" > gadoProcessInput.tsv
  for i in $(echo "!{gadoHpoIds}" | sed "s/,/ /g")
  do
      echo -e -n "\t${i}" >> gadoProcessInput.tsv
  done

  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toMega() - 256}m")
  args+=("-jar" "/opt/gado/lib/GADO.jar")
  args+=("--mode" "PROCESS")
  args+=("--output" "gadoProcessOutput.tsv")
  args+=("--caseHpo" "gadoProcessInput.tsv")
  args+=("--hpoOntology" "!{gadoHpoPath}")
  args+=("--hpoPredictionsInfo" "!{gadoPredictInfoPath}")

  ${CMD_GADO} java "${args[@]}"
}

gado_prioritize() {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toMega() - 256}m")
  args+=("-jar" "/opt/gado/lib/GADO.jar")
  args+=("--mode" "PRIORITIZE")
  args+=("--output" "./gado")
  args+=("--caseHpoProcessed" "gadoProcessOutput.tsv")
  args+=("--genes" "!{gadoGenesPath}")
  args+=("--hpoPredictions" "!{gadoPredictMatrixPath}")

  ${CMD_GADO} java "${args[@]}"

  # workaround for GADO sometimes not producing a all_samples.txt after successfull exit
  # https://github.com/molgenis/systemsgenetics/issues/663
  if [[ ! -f "!{gadoScores}" ]]; then
    echo -e "Ensg\tHgnc\tRank\tZscore\t$(sed "s/,/\t/g" <<< "!{gadoHpoIds}")" > "!{gadoScores}"
  fi
}

main () {
    gado_process
    gado_prioritize
}

main "$@"