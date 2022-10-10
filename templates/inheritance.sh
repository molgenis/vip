#!/bin/bash

inheritance () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-inheritance-matcher/lib/vcf-inheritance-matcher.jar")
  args+=("--input" "!{vcfPath}")
  args+=("--output" "!{vcfInheritancePath}")
  if [ -n "!{params.pedigree}" ]; then
    args+=("--pedigree" "!{params.pedigree}")
  fi
  if [ -n "!{params.probands}" ]; then
    args+=("--probands" "!{params.probands}")
  fi

  !{CMD_VCFINHERITANCEMATCHER} java "${args[@]}"
}

inheritance
${CMD_BCFTOOLS} index "!{vcfInheritancePath}"