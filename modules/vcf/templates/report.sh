#!/bin/bash
set -euo pipefail

create_vcf () {
  printf "##VIP_Version=%s\n##VIP_Command=%s" "${VIP_VERSION}" "!{workflow.commandLine}" > "!{basename}.header"

  local args=()
  args+=("annotate")
  args+=("--header-lines" "!{basename}.header")
  args+=("--output-type" "z9")
  args+=("--output" "!{vcfOut}")
  args+=("--no-version")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcf}")

  ${CMD_BCFTOOLS} "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

report() {
  echo -e "!{pedigreeContent}" > "!{pedigree}"
  
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toMega() - 512}m")
  args+=("-jar" "/opt/vcf-report/lib/vcf-report.jar")
  args+=("--input" "!{vcfOut}")
  args+=("--metadata" "!{metadata}")
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
  if [ -n "!{sampleTree}" ]; then
    args+=("--sample_tree" "!{sampleTree}")
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
  if [ -n "!{config}" ]; then
    echo "!{configJsonStr}" > "vip_report_config.json"
    args+=("--template_config" "vip_report_config.json")
  fi
  if [ -n "!{crams}" ] && [[ "!{includeCrams}" == "true" ]]; then
    args+=("--cram" "!{crams}")
  fi

  ${CMD_VCFREPORT} java "${args[@]}"
}

main() {
  create_vcf
  index
  report
}

main "$@"
