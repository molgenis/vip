#!/bin/bash
set -euo pipefail

report() {
  echo -e "!{pedigreeContent}" > "!{pedigree}"
  
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-report/lib/vcf-report.jar")
  args+=("--input" "!{vcfOutputPath}")
  args+=("--reference" "!{refSeqPath}")
  args+=("--output" "!{reportPath}")
  if [ -n "!{probands}" ]; then
    args+=("--probands" "!{probands}")
  fi
  if [ -n "!{pedigree}" ]; then
    args+=("--pedigree" "!{pedigree}")
  fi
  if [ -n "!{hpoIds}" ]; then
    args+=("--phenotypes" "!{hpoIds}")
  fi
  if [ -n "!{decisionTree}" ]; then
    args+=("--decision_tree" "!{decisionTree}")
  fi
  if [ -n "!{maxRecords}" ]; then
    args+=("--max_records" "!{maxRecords}")
  fi
  if [ -n "!{maxSamples}" ]; then
    args+=("--max_samples" "!{maxSamples}")
  fi
  if [ -n "!{genesPath}" ]; then
    args+=("--genes" "!{genesPath}")
  fi
  if [ -n "!{template}" ]; then
    args+=("--template" "!{template}")
  fi
  if [ -n "!{crams}" ]; then
    args+=("--cram" "!{crams}")
  fi

  !{CMD_VCFREPORT} java "${args[@]}"
}

main() {
  report
}

main "$@"
