#!/bin/bash
filter () {
  args+=("-i" "!{vcfPath}")

  local operator;
  if [[ "!{params.filter_classes}" =~ .+,.+ ]]; then
    args+=("-f" "VIPC in !{params.filter_classes}")
  else
    args+=("-f" "VIPC is !{params.filter_classes}")
  fi
  if [ "!{params.filter_consequences}" = true ]; then
    args+=("--only_matched")
  fi

  !{CMD_FILTERVEP} filter_vep "${args[@]}"  | !{CMD_BGZIP} -c > "!{vcfFilteredPath}"
}

filter
${CMD_BCFTOOLS} index "!{vcfFilteredPath}"
