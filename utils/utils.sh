#!/bin/bash

#######################################
# Checks whether an item is contained in an array.
#
# Arguments:
#   item
#   array
# Returns:
#   0 if the array contains the item
#   1 if that array doesn't contain the item
#######################################
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

#######################################
# Returns whether probands exist in VCF file.
#
# Arguments:
#   proband names (comma-separated string)
#   path to VCF file
# Returns:
#   0 if the VCF file contains all proband names
#   1 if the VCF file doesn't contain one or more proband names.
#######################################
containsProbands () {
  if [ -z "$1" ]; then
    return 0
  fi

  # shellcheck disable=SC2206
  local PROBAND_NAMES=(${1//,/ })
  local VCF_PATH=$2

  # get sample names from vcf
  local VCF_SAMPLE_NAMES=()
  module load "${MOD_BCF_TOOLS}"
  mapfile -t VCF_SAMPLE_NAMES < <( bcftools query -l "${VCF_PATH}" )
  module purge

  # validate proband names
  for i in "${PROBAND_NAMES[@]}"; do
    if ! containsElement "$i" "${VCF_SAMPLE_NAMES[@]}"; then
      echo -e "Proband '$i' does not exist in '${VCF_PATH}'."
      return 1
    fi
  done

  return 0
}

#######################################
# Returns whether VCF file contains structural variants.
#
# Arguments:
#   path to VCF file
# Returns:
#   0 if the VCF file contains structural variants
#   1 if the VCF file doesn't contain structural variants
#######################################
containsStructuralVariants () {
  local VCF_PATH=$1

  module load "${MOD_BCF_TOOLS}"
  local VCF_HEADER
  VCF_HEADER=$(bcftools view -h "${VCF_PATH}")
  module purge

  if [[ "${VCF_HEADER}" =~ .*ID=SVTYPE.* ]]
  then
    return 0
  else
    return 1
  fi
}
