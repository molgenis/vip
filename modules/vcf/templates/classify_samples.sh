#!/bin/bash

classify_samples () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcfPath}")
  args+=("--mode" "sample")
  args+=("--config" "!{params.vcf.classify_samples.decision_tree}")
  if [ !{params.vcf.classify_samples.annotate_labels} -eq 1 ]; then
    args+=("--labels")
  fi
  if [ !{params.vcf.classify_samples.annotate_path} -eq 1 ]; then
    args+=("--path")
  fi
  if [ -n "!{probands}" ]; then
    args+=("--probands" "!{probands}")
  fi
  args+=("--output" "!{vcfSamplesClassifiedPath}")

  !{CMD_VCFDECISIONTREE} java "${args[@]}"
}

classify_samples
${CMD_BCFTOOLS} index "!{vcfSamplesClassifiedPath}"