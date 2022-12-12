#!/bin/bash

report () {
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
  if [ -n "!{params.vcf.classify.decision_tree}" ]; then
    args+=("--decision_tree" "!{params.vcf.classify.decision_tree}")
  fi
  if [ -n "!{params.vcf.report.max_records}" ]; then
    args+=("--max_records" "!{params.vcf.report.max_records}")
  fi
  if [ -n "!{params.vcf.report.max_samples}" ]; then
    args+=("--max_samples" "!{params.vcf.report.max_samples}")
  fi
  if [ -n "!{genesPath}" ]; then
    args+=("--genes" "!{genesPath}")
  fi
  if [ -n "!{params.vcf.report.template}" ]; then
    args+=("--template" "!{params.vcf.report.template}")
  fi
  #FIXME include crams

  !{CMD_VCFREPORT} java "${args[@]}"
}

echo -e "!{pedigreeContent}" > "!{pedigree}"

report
