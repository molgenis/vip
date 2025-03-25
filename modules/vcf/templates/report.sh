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

  # workaround for https://github.com/samtools/bcftools/issues/2385
  ${CMD_BCFTOOLS} view --no-version --threads "!{task.cpus}" "!{vcf}" | ${CMD_BCFTOOLS} "${args[@]}"
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
  args+=("--input" "!{vcfOut}_filtered_samples.vcf.gz")
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
  cat << EOF > "vip_report_config.json"
!{configJsonStr}
EOF
  args+=("--template_config" "vip_report_config.json")
  if [ -n "!{crams}" ] && [[ "!{includeCrams}" == "true" ]]; then
    args+=("--cram" "!{crams}")
  fi

  ${CMD_VCFREPORT} java "${args[@]}"
}

#Filter report VCF for maximum number of samples
filter_samples() {
  if [ -n "!{maxSamples}" ]; then
    ${CMD_BCFTOOLS} query --list-samples !{vcfOut} > samples.txt
    head -n "!{maxSamples}" samples.txt > selected_samples.txt
    ${CMD_BCFTOOLS} view --samples-file selected_samples.txt !{vcfOut} --output-type z --output !{vcfOut}_filtered_samples.vcf.gz
    ${CMD_BCFTOOLS} index --csi --output "!{vcfOut}_filtered_samples.vcf.gz.csi" --threads "!{task.cpus}" "!{vcfOut}_filtered_samples.vcf.gz"
  else
    cp --link "!{vcfOut}" "!{vcfOut}_filtered_samples.vcf.gz"
    cp --link "!{vcfOutIndex}" "!{vcfOut}_filtered_samples.vcf.gz.csi"
  fi
  
}

cleanup() {
  rm -f !{vcfOut}_filtered_samples.vcf.gz !{vcfOut}_filtered_samples.vcf.gz.csi selected_samples.txt samples.txt
}

main() {
  create_vcf
  index
  filter_samples
  report
  cleanup
}

main "$@"
