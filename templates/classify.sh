#!/bin/bash

classify () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcfPath}")
  args+=("--config" "!{params.classify_decision_tree}")
  if [ !{params.classify_annotate_labels} -eq 1 ]; then
    args+=("--labels")
  fi
  if [ !{params.classify_annotate_path} -eq 1 ]; then
    args+=("--path")
  fi

  args+=("--output" "!{vcfClassifiedPath}")

  !{singularity_vcfdecisiontree} java "${args[@]}"
}

classify
