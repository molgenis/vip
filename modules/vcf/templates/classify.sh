#!/bin/bash
set -euo pipefail

classify () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-Xmx!{task.memory.toGiga()}g")
  args+=("-jar" "/opt/vcf-decision-tree/lib/vcf-decision-tree.jar")
  args+=("--input" "!{vcf}")
  args+=("--config" "!{decisionTree}")
  if [ !{annotateLabels} -eq 1 ]; then
    args+=("--labels")
  fi
  if [ !{annotatePath} -eq 1 ]; then
    args+=("--path")
  fi

  args+=("--output" "!{vcfOut}")

  ${CMD_VCFDECISIONTREE} java "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main () {
  classify
  index
}

main "$@"