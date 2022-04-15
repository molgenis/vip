#!/bin/bash
filter () {
  args+=("-i" "!{vcfPath}")
  args+=("-f" "VIPC in !{params.filter_classes}")
  if [ "!{params.filter_consequences}" = true ]; then
    args+=("--only_matched")
  fi

  !{singularity_vep} filter_vep "${args[@]}"  | !{singularity_vep} bgzip -c > "!{vcfFilteredPath}"
}

filter
