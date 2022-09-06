#!/bin/bash

# creates string with specified separator from an array.
#
# arguments:
#   separator
#   elements to be joined
join_arr() {
  local IFS="$1"
  shift
  echo -e "$*"
}

index_tbi () {
  local args=()
  args+=("index")
  # realign requires tbi index instead of csi index
  args+=("--tbi")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfPath}")

  !{singularity_bcftools} bcftools "${args[@]}"
}

realign () {
  local -r input_bam="${1}"
  local -r output_bam="${2}"

  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/gatk/lib/gatk.jar")
  args+=("HaplotypeCaller")
  args+=("--tmp-dir" "${TMPDIR}")
  args+=("-R" "!{refSeqPath}")
  args+=("-I" "${input_bam}")
  args+=("-L" "!{vcfPath}")
  args+=("-ip" "250")
  args+=("--force-active")
  # todo: workaround for https://github.com/broadinstitute/gatk/issues/7123
  #args+=("--disable-optimizations")
  args+=("-O" "${output_bam}.vcf.gz")
  args+=("-OVI" "false")
  args+=("-bamout" "${output_bam}")

  !{singularity_gatk} java "${args[@]}"
}

index () {
  local args=()
  args+=("index")
  args+=("--threads" "!{task.cpus}")
  args+=("!{vcfOutputPath}")

  !{singularity_bcftools} bcftools "${args[@]}"
}

report () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-report/lib/vcf-report.jar")
  args+=("--input" "!{vcfOutputPath}")
  args+=("--reference" "!{refSeqPath}")
  args+=("--output" "!{reportPath}")
  if [ -n "!{params.probands}" ]; then
    args+=("--probands" "!{params.probands}")
  fi
  if [ -n "!{params.pedigree}" ]; then
    args+=("--pedigree" "!{params.pedigree}")
  fi
  if [ -n "!{params.phenotypes}" ]; then
    args+=("--phenotypes" "!{params.phenotypes}")
  fi
  if [ -n "!{params.classify_decision_tree}" ]; then
    args+=("--decision_tree" "!{params.classify_decision_tree}")
  fi
  if [ -n "!{params.report_max_records}" ]; then
    args+=("--max_records" "!{params.report_max_records}")
  fi
  if [ -n "!{params.report_max_samples}" ]; then
    args+=("--max_samples" "!{params.report_max_samples}")
  fi
  if [ -n "!{genesPath}" ]; then
    args+=("--genes" "!{genesPath}")
  fi
  if [ -n "!{params.report_template}" ]; then
    args+=("--template" "!{params.report_template}")
  fi
  if [ -n "!{params.report_bams}" ]; then
    args+=("--bam" "$(join_arr "," "${realigned_bams[@]}")")
  fi

  !{singularity_vcfreport} java "${args[@]}"
}

index_tbi

if [ -n "!{params.report_bams}" ]; then
  realigned_bams=()

  IFS=',' read -ra bams <<< "!{params.report_bams}"
  for entry in "${bams[@]}"; do
    while IFS='=' read -r sample_id input_bam; do
      output_bam="realigned_$(basename "${input_bam}")"
      realign "${input_bam}" "${output_bam}"
      mv "${output_bam/.bam/.bai}" "${output_bam}.bai"
      realigned_bams+=("${sample_id}=${output_bam}")
    done <<< "${entry}"
  done
fi

cp --preserve=links "!{vcfPath}" "!{vcfOutputPath}"
index
md5sum "!{vcfOutputPath}" > "!{vcfOutputPath}.md5" 

report
md5sum "!{reportPath}" > "!{reportPath}.md5"
