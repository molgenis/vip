#!/bin/bash

#######################################
# Returns whether a variable is set.
#
# Arguments:
#   variable name
# Returns:
#   0 if variable is set
#   1 if variable is not set
#######################################
isVariableSet() {
  declare -p "$1" &>/dev/null
}

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
containsElement() {
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
containsProbands() {
  if [ -z "$1" ]; then
    return 0
  fi

  # shellcheck disable=SC2206
  local PROBAND_NAMES=(${1//,/ })
  local VCF_PATH=$2

  # get sample names from vcf
  local VCF_SAMPLE_NAMES=()
  module load "${MOD_BCF_TOOLS}"
  mapfile -t VCF_SAMPLE_NAMES < <(bcftools query -l "${VCF_PATH}")
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
# Returns whether VCF file contains a FORMAT/DP header.
#
# Arguments:
#   path to VCF file
# Returns:
#   0 if the VCF file contains a FORMAT/DP header
#   1 if the VCF file doesn't contain a FORMAT/DP header
#######################################
containsFormatDpHeader() {
  local VCF_PATH=$1

  local VCF_HEADER
  VCF_HEADER=$(bcftools view -h "${VCF_PATH}")

  if [[ "${VCF_HEADER}" =~ .*ID=DP.* ]]; then
    return 0
  else
    return 1
  fi
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
containsStructuralVariants() {
  local VCF_PATH=$1

  module load "${MOD_BCF_TOOLS}"
  local VCF_HEADER
  VCF_HEADER=$(bcftools view -h "${VCF_PATH}")
  module purge

  if [[ "${VCF_HEADER}" =~ .*ID=SVTYPE.* ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Returns whether VCF file contains InheritanceModesGene annotations.
#
# Arguments:
#   path to VCF file
# Returns:
#   0 if the VCF file contains InheritanceModesGene annotations
#   1 if the VCF file doesn't contain InheritanceModesGene annotations
#######################################
containsInheritanceModesGeneAnnotations() {
  local VCF_PATH=$1

  module load "${MOD_BCF_TOOLS}"
  local VCF_HEADER
  VCF_HEADER=$(bcftools view -h "${VCF_PATH}")
  module purge

  if [[ "${VCF_HEADER}" =~ .*##InheritanceModesGene.* ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Parses config file into associative array 'cfgArray'.
#
# Requirements:
#   associative array 'VIP_CFG_MAP' exists
# Arguments:
#   path to config file
# Returns:
#   1 on config file parse failure
#######################################
parseCfg() {
  if ! isVariableSet VIP_CFG_MAP; then
    echo -e "associative array 'VIP_CFG_MAP' not set."
    return 1
  fi

  local cfgPath=$1
  if [[ ! -f "${cfgPath}" ]]; then
    echo -e "config ${cfgPath} does not exist."
    return 1
  fi

  while IFS="=" read -r key value; do
    if [[ ! ${key} =~ ^# ]] && [[ ! ${key} == "" ]]; then
      # shellcheck disable=SC2034
      VIP_CFG_MAP["${key}"]="${value}"
    fi
  done <"${cfgPath}"
}

# exports VIP_WORK_DIR variable if it is unset
#
# arguments:
#   $1 path to output file
#   $2 whether to keep intermediate outputs (0: false, 1: true)
initWorkDir() {
  local -r outputFilePath="${1}"
  local -r keep="${2}"

  if [ -z "${VIP_WORK_DIR+x}" ]; then
    if [[ "${keep}" == "1" ]]; then
      VIP_WORK_DIR="$(dirname "${outputFilePath}")/$(basename "${outputFilePath}")_results"
      mkdir -p "${VIP_WORK_DIR}"
    else
      # shellcheck disable=SC2153
      VIP_WORK_DIR="${TMP_WORK_DIR}"
    fi
    export VIP_WORK_DIR
  fi
}

# arguments:
#   $1 whether to force overwrite intermediate outputs (0: false, 1: true)
removeWorkDir() {
  local -r force="${1}"

  if [[ -d "${VIP_WORK_DIR}" ]]; then
    if [[ "${force}" == "1" ]]; then
      rm -r "${VIP_WORK_DIR}"
    else
      echo -e "working directory ${VIP_WORK_DIR} already exists, use -f to overwrite."
    fi
  fi
}

# arguments:
#   $1 path to input file
# returns:
#    1 if path to input file is invalid
validateInputPath() {
  local -r inputPath="${1}"
  if [[ -z "${inputPath+unset}" ]]; then
    echo -e "missing required option -i."
    return 1
  fi
  if [[ ! -f "${inputPath}" ]]; then
    echo -e "input ${inputPath} does not exist."
    return 1
  fi
  if ! [[ "${inputPath}" =~ (.+)(\.vcf|\.vcf.gz) ]]; then
    echo -e "input ${inputPath} is not a .vcf or .vcf.gz file"
    return 1
  fi
}

# arguments:
#   $1 path to output file
#   $2 overwrite output file (0: false, 1: true)
# returns:
#    1 if path to output file is invalid
validateOutputPath() {
  local -r outputFilePath="${1}"
  local -r overwrite="${2}"

  if ! [[ "${outputFilePath}" =~ .*\.vcf\.gz ]]; then
    echo -e "output ${outputFilePath} is not a .vcf.gz file."
    return 1
  fi

  if [[ "${overwrite}" == "0" ]] && [[ -f "${outputFilePath}" ]]; then
    echo -e "output ${outputFilePath} already exists, use -f to overwrite."
    return 1
  fi
}

# arguments:
#   $1 path to output file
#   $2 postfix
createOutputPathFromPostfix() {
  local -r outputFilePath="${1}"
  local -r postfix="${2}"

  local -r outputDir="$(dirname "${outputFilePath}")"
  local -r outputFilename="$(basename "${outputFilePath}")"
  if [[ "${outputFilename}" =~ (.+)(\.(bcf|vcf(\.gz)?))$ ]]; then
    echo -e "${outputDir}/${BASH_REMATCH[1]}_${postfix}.vcf.gz"
  else
    return 1
  fi
}

#######################################
# Creates string with specified separator from an array.
#
# Arguments:
#   separator
#   elements to be joined
#######################################
joinArr() {
  local IFS="$1"
  shift
  echo -e "$*"
}

# arguments:
#   $1 path to input file
# returns:
#    0 if input contains samples
#    1 if input doesn't contain samples
hasSamples() {
  local -r inputFilePath="${1}"

  module load "${MOD_BCF_TOOLS}"
  local -r samples="$(bcftools query -l "${inputFilePath}")"
  module purge

  if [[ -n ${samples} ]]; then
    return 0
  else
    return 1
  fi
}
