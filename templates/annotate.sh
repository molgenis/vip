#!/bin/bash

# creates string with specified separator from an array.
#
# arguments:
#   separator
#   elements to be joined
join_arr() {
  local IFS="$1"
  shift
  echo -e "$*"
}

get_unique_phenotypes() {
  IFS=',' read -ra SAMPLE_PHENOTYPES <<<"$1"
  for i in "${SAMPLE_PHENOTYPES[@]}"; do
    if [[ "$i" =~ (.*\/)?(.*) ]]; then
      IFS=';' read -ra PHENOTYPES <<<"${BASH_REMATCH[2]}"
      for j in "${PHENOTYPES[@]}"; do
        UNIQUE_PHENOTYPES["$j"]=1
      done
    else
      echo -e "Invalid phenotype '${phenotypes}' in -t or --phenotypes\n"
      usage
      exit 2
    fi
  done
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
contains_sv () {
  local -r vcf_path="${1}"

  local vcf_header
  vcf_header=$(!{singularity_bcftools} bcftools view -h "${vcf_path}")

  if [[ "${vcf_header}" =~ .*ID=SVTYPE.* ]]; then
    return 0
  else
    return 1
  fi
}

annot_sv () {
  local args=()
  args+=("-SVinputFile" "!{vcfPath}")
  args+=("-outputDir" ".")
  args+=("-outputFile" "!{vcfPath}.tsv")
  args+=("-genomeBuild" "!{params.assembly}")
  args+=("-annotationMode" "full")
  args+=("-annotationsDir" "!{params.annotate_annotsv_cache_dir}")
  if [ -n "!{params.phenotypes}" ]; then
    args+=("-hpo" "$(join_arr "," "${!UNIQUE_PHENOTYPES[@]}")")
  fi
  !{singularity_annotsv} AnnotSV "${args[@]}"
  if [ ! -f "!{vcfPath}.tsv" ]; then
    echo -e "AnnotSV error: failed to produce output" 1>&2
    exit 1
  fi
}

vep () {
  local args=()
  args+=("--input_file" "!{vcfPath}")
  args+=("--format" "vcf")
  args+=("--output_file" "!{vcfAnnotatedPath}")
  args+=("--vcf")
  args+=("--compress_output" "bgzip")
  args+=("--no_stats")
  args+=("--fasta" "!{refSeqPath}")
  args+=("--hgvs")
  args+=("--offline")
  args+=("--cache")
  args+=("--dir_cache" "!{params.annotate_vep_cache_dir}")
  args+=("--species" "homo_sapiens")
  args+=("--assembly" "!{params.assembly}")
  args+=("--refseq")
  args+=("--exclude_predicted")
  args+=("--use_given_ref")
  args+=("--symbol")
  args+=("--flag_pick_allele")
  args+=("--sift" "s")
  args+=("--polyphen" "s")
  args+=("--regulatory")
  args+=("--domains")
  args+=("--total_length")
  args+=("--pubmed")
  args+=("--shift_3prime" "1")
  args+=("--allele_number")
  args+=("--numbers")
  args+=("--dont_skip")
  args+=("--allow_non_variant")
  args+=("--buffer_size" "!{params.annotate_vep_buffer_size}")
  args+=("--fork" "!{task.cpus}")
  args+=("--dir_plugins" "!{params.annotate_vep_plugin_dir}")
  if [ -n "!{vepPluginArtefact}" ]; then
    args+=("--plugin" "Artefact,!{vepPluginArtefact}")
  fi
  if [ -n "!{params.phenotypes}" ]; then
    args+=("--plugin" "Hpo,!{params.annotate_vep_plugin_hpo},$(join_arr ";" "${!UNIQUE_PHENOTYPES[@]}")")
  fi
  args+=("--plugin" "Inheritance,!{params.annotate_vep_plugin_inheritance}")
  if [ -n "!{vepPluginSpliceAiSnvPath}" ] && [ -n "!{vepPluginSpliceAiIndelPath}" ]; then
    args+=("--plugin" "SpliceAI,snv=!{vepPluginSpliceAiSnvPath},indel=!{vepPluginSpliceAiIndelPath}")
  fi
  if [ -n "!{vepPluginVkglPath}" ] && [ -n "!{params.annotate_vep_plugin_vkgl_mode}" ]; then
    args+=("--plugin" "VKGL,!{vepPluginVkglPath},!{params.annotate_vep_plugin_vkgl_mode}")
  fi
  if [ -n "!{vepCustomGnomAdPath}" ]; then
    args+=("--custom" "!{vepCustomGnomAdPath},gnomAD,vcf,exact,0,AF,HN")
  fi
  if [ -f "!{vcfPath}.tsv" ]; then
    args+=("--plugin" "AnnotSV,!{vcfPath}.tsv,AnnotSV_ranking_score;AnnotSV_ranking_criteria;ACMG_class")
  fi

  !{singularity_vep} vep "${args[@]}"
}

if [ -n "!{params.phenotypes}" ]; then
  declare -A UNIQUE_PHENOTYPES
  get_unique_phenotypes "!{params.phenotypes}"
fi

if [ -n "!{params.annotate_annotsv_cache_dir}" ] && contains_sv "!{vcfPath}"; then
  annot_sv
fi

vep
