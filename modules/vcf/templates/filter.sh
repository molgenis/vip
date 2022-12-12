#!/bin/bash
filter () {
  args+=("-i" "!{vcfPath}")

  local operator;
  if [[ "!{params.vcf.filter.classes}" =~ .+,.+ ]]; then
    args+=("-f" "VIPC in !{params.vcf.filter.classes}")
  else
    args+=("-f" "VIPC is !{params.vcf.filter.classes}")
  fi
  if [ "!{params.vcf.filter.consequences}" = true ]; then
    args+=("--only_matched")
  fi

  !{CMD_FILTERVEP} filter_vep "${args[@]}"  | !{CMD_BGZIP} -c > "!{vcfFilteredPath}"
}

filter
${CMD_BCFTOOLS} index "!{vcfFilteredPath}"
