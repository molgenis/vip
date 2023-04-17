#!/bin/bash
set -euo pipefail

classify_samples() {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcf}")
  args+=("--mode" "sample")
  args+=("--config" "!{decisionTree}")
  if [ !{annotateLabels} -eq 1 ]; then
    args+=("--labels")
  fi
  if [ !{annotatePath} -eq 1 ]; then
    args+=("--path")
  fi
  if [ -n "!{probands}" ]; then
    args+=("--probands" "!{probands}")
  fi
  args+=("--output" "!{vcfOut}")

  !{params.CMD_VCFDECISIONTREE} java "${args[@]}"
}

index () {
  !{params.CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  !{params.CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main() {
  classify_samples
  index
}

main "$@"
