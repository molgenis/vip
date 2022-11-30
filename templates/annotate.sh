#!/bin/bash

#######################################
# Returns whether VCF file contains structural variants.
#
# Arguments:
#   path to VCF file
# Returns:
#   0 if the VCF file contains structural variants
#   1 if the VCF file doesn't contain structural variants
#######################################
contains_sv() {
  local -r vcf_path="${1}"

  local vcf_header
  vcf_header=$(!{CMD_BCFTOOLS} view -h "${vcf_path}")

  if [[ "${vcf_header}" =~ .*ID=SVTYPE.* ]]; then
    return 0
  else
    return 1
  fi
}

annot_sv() {
  local args=()
  args+=("-SVinputFile" "!{vcfPath}")
  args+=("-outputDir" ".")
  args+=("-outputFile" "!{vcfPath}.tsv")
  args+=("-genomeBuild" "!{params.assembly}")
  args+=("-annotationMode" "full")
  args+=("-annotationsDir" "!{params.annotate_annotsv_cache_dir}")
  if [ -n "!{hpoIds}" ]; then
    args+=("-hpo" "!{hpoIds}")
  fi
  !{CMD_ANNOTSV} "${args[@]}"
  if [ ! -f "!{vcfPath}.tsv" ]; then
    echo -e "AnnotSV error: failed to produce output" 1>&2
    exit 1
  fi
}

capice() {
  capice_vep
  capice_bcftools
  capice_predict
}

capice_vep() {
  local args=()
  args+=("--input_file" "!{vcfPath}")
  args+=("--format" "vcf")
  args+=("--output_file" "!{vcfCapiceAnnotatedPath}")
  args+=("--vcf")
  args+=("--compress_output" "bgzip")
  args+=("--no_stats")
  args+=("--fasta" "!{refSeqPath}")
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
  args+=("--total_length")
  args+=("--shift_3prime" "1")
  args+=("--allele_number")
  args+=("--numbers")
  args+=("--dont_skip")
  args+=("--allow_non_variant")
  args+=("--buffer_size" "!{params.annotate_vep_buffer_size}")
  args+=("--fork" "!{task.cpus}")
  args+=("--dir_plugins" "!{params.annotate_vep_plugin_dir}")
  args+=("--plugin" "SpliceAI,snv=!{vepPluginSpliceAiSnvPath},indel=!{vepPluginSpliceAiIndelPath}")
  args+=("--plugin" "Grantham")
  args+=("--custom" "!{vepCustomPhyloPPath},phyloP,bigwig,exact,0")

  !{CMD_VEP} vep "${args[@]}"

  if [ ! -f "!{vcfCapiceAnnotatedPath}" ]; then
    echo -e "VEP error: failed to create capice input" 1>&2
    exit 1
  fi
}

capice_bcftools() {
  local -r format="%CHROM\t%POS\t%REF\t%ALT\t%CSQ\n"
  local -r header="CHROM\tPOS\tREF\tALT\t"
  local -r capiceInputPathHeaderless="!{capiceInputPath}.headerless"

  local args=()
  args+=("+split-vep")
  args+=("-d")
  args+=("-f" "${format}\n")
  args+=("-A" "tab")
  args+=("-o" "${capiceInputPathHeaderless}")
  args+=("!{vcfCapiceAnnotatedPath}")

  !{CMD_BCFTOOLS} "${args[@]}"

  echo -e "${header}$(!{CMD_BCFTOOLS} +split-vep -l "!{vcfCapiceAnnotatedPath}" | cut -f 2 | tr '\n' '\t' | sed 's/\t$//')" | cat - "${capiceInputPathHeaderless}" > "!{capiceInputPath}"
}

capice_predict() {
  local args=()
  args+=("predict")
  args+=("--input" "!{capiceInputPath}")
  args+=("--output" "!{capiceOutputPath}")
  args+=("--model" "!{capiceModelPath}")

  !{CMD_CAPICE} "${args[@]}"
  if [ ! -f "!{capiceOutputPath}" ]; then
    echo -e "CAPICE error: failed to produce output" 1>&2
    exit 1
  fi
}

vep() {
  local args=()
  args+=("--input_file" "!{vcfPath}")
  args+=("--format" "vcf")
  args+=("--output_file" "!{vcfAnnotatedPath}")
  args+=("--vcf")
  args+=("--compress_output" "bgzip")
  args+=("--no_stats")
  args+=("--fasta" "!{refSeqPath}")
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
  args+=("--total_length")
  args+=("--pubmed")
  args+=("--shift_3prime" "1")
  args+=("--allele_number")
  args+=("--numbers")
  args+=("--dont_skip")
  args+=("--allow_non_variant")
  args+=("--buffer_size" "!{params.annotate_vep_buffer_size}")
  args+=("--fork" "!{task.cpus}")
  args+=("--hgvs")
  args+=("--pubmed")
  args+=("--dir_plugins" "!{params.annotate_vep_plugin_dir}")
  args+=("--plugin" "Grantham")
  args+=("--plugin" "SpliceAI,snv=!{vepPluginSpliceAiSnvPath},indel=!{vepPluginSpliceAiIndelPath}")
  args+=("--plugin" "Capice,!{capiceOutputPath}")
  args+=("--plugin" "UTRannotator,!{vepPluginUtrAnnotatorPath}")
  args+=("--custom" "!{vepCustomPhyloPPath},phyloP,bigwig,exact,0")

  if [ -n "!{vepPluginArtefact}" ]; then
    args+=("--plugin" "Artefact,!{vepPluginArtefact}")
  fi
  if [ -n "!{hpoIds}" ]; then
    args+=("--plugin" "Hpo,!{params.annotate_vep_plugin_hpo},!{hpoIds.replace(',', ';')}")
  fi
  args+=("--plugin" "Inheritance,!{params.annotate_vep_plugin_inheritance}")
  if [ -n "!{vepPluginVkglPath}" ] && [ -n "!{params.annotate_vep_plugin_vkgl_mode}" ]; then
    args+=("--plugin" "VKGL,!{vepPluginVkglPath},!{params.annotate_vep_plugin_vkgl_mode}")
  fi
  if [ -n "!{vepCustomGnomAdPath}" ]; then
    args+=("--custom" "!{vepCustomGnomAdPath},gnomAD,vcf,exact,0,AF,HN")
  fi
  if [ -n "!{vepCustomClinVarPath}" ]; then
      args+=("--custom" "!{vepCustomClinVarPath},clinVar,vcf,exact,0,CLNSIG,CLNSIGINCL,CLNREVSTAT")
  fi
  if [ -f "!{vcfPath}.tsv" ]; then
    args+=("--plugin" "AnnotSV,!{vcfPath}.tsv,AnnotSV_ranking_score;AnnotSV_ranking_criteria;ACMG_class")
  fi

  !{CMD_VEP} "${args[@]}"
}

if [ -n "!{params.annotate_annotsv_cache_dir}" ] && contains_sv "!{vcfPath}"; then
  annot_sv
fi

capice
vep
${CMD_BCFTOOLS} index "!{vcfAnnotatedPath}"