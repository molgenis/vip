#!/bin/bash

inheritance () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${TMPDIR}\"")
  args+=("-XX:ParallelGCThreads=2")
  args+=("-jar" "/opt/vcf-inheritance-matcher/lib/vcf-inheritance-matcher.jar")
  args+=("--input" "!{vcfPath}")
  args+=("--output" "!{vcfInheritancePath}")
  if [ -n "!{pedigree}" ]; then
    args+=("--pedigree" "!{pedigree}")
  fi
  if [ -n "!{probands}" ]; then
    args+=("--probands" "!{probands}")
  fi

  !{CMD_VCFINHERITANCEMATCHER} java "${args[@]}"
}

echo -e "!{pedigreeContent}" > "!{pedigree}"
inheritance
${CMD_BCFTOOLS} index "!{vcfInheritancePath}"