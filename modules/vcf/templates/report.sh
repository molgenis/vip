#!/bin/bash
set -euo pipefail

rna_param="";

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

process_rna () {
  if [ -n "!{rna_crams}" ] && [[ "!{includeCrams}" == "true" ]]; then
    for cram in !{rna_crams}; do
      IFS='=' read -r sampleId cram_value <<< "${cram}"
      filename=$(basename "${cram_value}" .cram)
      ${CMD_SAMTOOLS} view -b -T "!{refSeqPath}" -o "${filename}.bam" "${cram_value}"
      ${CMD_SAMTOOLS} index "${filename}.bam"
      #TODO: produce bed
      ${CMD_PORTCULLIS} portcullis prep "!{reference}" "${filename}.bam"
      ${CMD_PORTCULLIS} portcullis junc portcullis_prep/
      ${CMD_PORTCULLIS} junctools convert -if portcullis -of STAR portcullis_junc/portcullis.junctions.tab
      mv portcullis_junc/portcullis.junctions.bed $filename.bed

      #produce bigwig
      local args_deep=()
      args_deep+=("-b" "${filename}.bam")
      args_deep+=("-o" "${filename}.bw")
      ${CMD_DEEPTOOLS} "${args_deep[@]}"
      
      #create file pair for merged igv track
      if [[ -n "$rna_param" ]]; then
          rna_param+=","
      fi
      rna_param+="${sampleId}=$(realpath "${filename}.bw");$(realpath "${filename}.bed")"
    done
  fi
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
  if [[ -n "$rna_param" ]]; then
    args+=("--rna" "$rna_param")
  fi
  cat << EOF > "vip_report_config.json"
!{configJsonStr}
EOF
  args+=("--template_config" "vip_report_config.json")
  if [ -n "!{crams}" ] && [[ "!{includeCrams}" == "true" ]]; then
    args+=("--cram" "!{crams}")
  fi

  echo -e "${args[@]}" > report_params.log
exit 1
  ${CMD_VCFREPORT} java "${args[@]}"
}

main() {
  process_rna
  create_vcf
  index
  report
}

main "$@"
