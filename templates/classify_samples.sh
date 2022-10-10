#!/bin/bash

classify_samples () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcfPath}")
  args+=("--mode" "sample")
  args+=("--config" "!{params.classify_samples_decision_tree}")
  if [ !{params.classify_samples_annotate_labels} -eq 1 ]; then
    args+=("--labels")
  fi
  if [ !{params.classify_samples_annotate_path} -eq 1 ]; then
    args+=("--path")
  fi
  if [ -n "!{params.probands}" ]; then
    args+=("--probands" "!{params.probands}")
  fi
  args+=("--output" "!{vcfSamplesClassifiedPath}")

  !{CMD_VCFDECISIONTREE} java "${args[@]}"
}

classify_samples
${CMD_BCFTOOLS} index "!{vcfSamplesClassifiedPath}"