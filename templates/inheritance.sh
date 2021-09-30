#!/bin/bash
if [ -z "${TMPDIR}" ]; then
  tmp_dir="$(mktemp -d)"
else
  tmp_dir="${TMPDIR}"
fi

inheritance () {
  local args=()
  args+=("-Djava.io.tmpdir=\"${tmp_dir}\"")
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

  !{singularity_vcfinheritancematcher} java "${args[@]}"
}

inheritance
