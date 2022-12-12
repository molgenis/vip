#!/bin/bash

classify () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcfPath}")
  args+=("--config" "!{params.vcf.classify.decision_tree}")
  if [ !{params.vcf.classify.annotate_labels} -eq 1 ]; then
    args+=("--labels")
  fi
  if [ !{params.vcf.classify.annotate_path} -eq 1 ]; then
    args+=("--path")
  fi

  args+=("--output" "!{vcfClassifiedPath}")

  !{CMD_VCFDECISIONTREE} java "${args[@]}"
}

classify
${CMD_BCFTOOLS} index "!{vcfClassifiedPath}"