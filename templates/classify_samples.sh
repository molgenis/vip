#!/bin/bash
if [ -z "${TMPDIR}" ]; then
  tmp_dir="$(mktemp -d)"
else
  tmp_dir="${TMPDIR}"
fi

classify_samples () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${tmp_dir}\"")
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

  !{singularity_vcfdecisiontree} java "${args[@]}"
}

classify_samples
