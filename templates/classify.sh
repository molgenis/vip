#!/bin/bash
if [ -z "${TMPDIR}" ]; then
  tmp_dir="$(mktemp -d)"
else
  tmp_dir="${TMPDIR}"
fi

classify () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${tmp_dir}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcfPath}")
  args+=("--config" "!{params.classify_decision_tree}")
  args+=("--labels" "!{params.classify_annotate_labels}")
  args+=("--path" "!{params.classify_annotate_path}")
  args+=("--output" "!{vcfClassifiedPath}")

  !{singularity_vcfdecisiontree} java "${args[@]}"
}

classify
