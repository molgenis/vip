#!/bin/bash
set -euo pipefail

capiceOutputPath="!{basename}_capice_output.tsv.gz"
vcfCapiceAnnotatedPath="!{basename}_capice_annotated.vcf.gz"
capiceInputPath="!{basename}_capice_input.tsv"
capiceOutputPath="!{basename}_capice_output.tsv.gz"

annot_sv() {
  local args=()
  args+=("-SVinputFile" "!{vcf}")
  args+=("-outputDir" ".")
  args+=("-outputFile" "!{vcf}.tsv")
  args+=("-genomeBuild" "!{meta.assembly}")
  args+=("-annotationMode" "full")
  args+=("-annotationsDir" "!{params.vcf.annotate.annotsv_cache_dir}")
  if [ -n "!{hpoIds}" ]; then
    args+=("-hpo" "!{hpoIds}")
  fi
  ${CMD_ANNOTSV} "${args[@]}"
  
  # AnnotSV potentially exists with the following message without creating a .tsv file
  # ############################################################################
  # No SV to annotate in the SVinputFile - Exit without error.
  # ############################################################################
  
  # write an empty file so that the AnnotSV VEP plugin is always used to ensure an equal number of VEP fields accross chunks
  if [[ ! -f "!{vcf}.tsv" ]]; then
    echo -e "AnnotSV_ranking_score\tAnnotSV_ranking_criteria\tACMG_class\n" > "!{vcf}.tsv"
  elif [[ "!{meta.assembly}" == "GRCh38" ]]; then
    # workaround for https://github.com/lgmgeo/AnnotSV/issues/152 that might fail for some chromosomes e.g. GRCh37 MT maps to GRCh38 chrM)
    mv "!{vcf}.tsv" "!{vcf}.tsv.tmp"
    awk -v FS='\t' -v OFS='\t' 'NR>1 {$2 = "chr"$2} 1' "!{vcf}.tsv.tmp" > "!{vcf}.tsv"
  fi
}

capice() {
  capice_vep
  capice_bcftools
  capice_predict
}

capice_vep() {
  local args=()
  args+=("--input_file" "!{vcf}")
  args+=("--format" "vcf")
  args+=("--output_file" "${vcfCapiceAnnotatedPath}")
  args+=("--vcf")
  args+=("--compress_output" "bgzip")
  args+=("--no_stats")
  args+=("--fasta" "!{refSeqPath}")
  args+=("--offline")
  args+=("--cache")
  args+=("--dir_cache" "!{params.vcf.annotate.vep_cache_dir}")
  args+=("--species" "homo_sapiens")
  args+=("--assembly" "!{meta.assembly}")
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
  args+=("--buffer_size" "!{params.vcf.annotate.vep_buffer_size}")
  args+=("--fork" "!{task.cpus}")
  args+=("--dir_plugins" "!{params.vcf.annotate.vep_plugin_dir}")
  args+=("--plugin" "SpliceAI,snv=!{vepPluginSpliceAiSnvPath},indel=!{vepPluginSpliceAiIndelPath}")
  args+=("--plugin" "Grantham")
  args+=("--custom" "!{vepCustomPhyloPPath},phyloP,bed,exact,0")

  ${CMD_VEP} "${args[@]}"
}

capice_bcftools() {
  local -r format="%CHROM\t%POS\t%REF\t%ALT\t%CSQ\n"
  local -r header="CHROM\tPOS\tREF\tALT\t"
  local -r capiceInputPathHeaderless="${capiceInputPath}.headerless"

  local args=()
  args+=("+split-vep")
  args+=("-d")
  args+=("-f" "${format}\n")
  args+=("-A" "tab")
  args+=("-o" "${capiceInputPathHeaderless}")
  args+=("${vcfCapiceAnnotatedPath}")

  ${CMD_BCFTOOLS} "${args[@]}"

  echo -e "${header}$(${CMD_BCFTOOLS} +split-vep -l "${vcfCapiceAnnotatedPath}" | cut -f 2 | tr '\n' '\t' | sed 's/\t$//')" | cat - "${capiceInputPathHeaderless}" > "${capiceInputPath}"
}

capice_predict() {
  local args=()
  args+=("predict")
  args+=("--input" "${capiceInputPath}")
  args+=("--output" "${capiceOutputPath}")
  args+=("--model" "!{capiceModelPath}")

  ${CMD_CAPICE} "${args[@]}"
  if [ ! -f "${capiceOutputPath}" ]; then
    echo -e "CAPICE error: failed to produce output" 1>&2
    exit 1
  fi
}

vep() {
  local args=()
  args+=("--input_file" "!{vcf}")
  args+=("--format" "vcf")
  args+=("--output_file" "!{vcfOut}")
  args+=("--vcf")
  args+=("--compress_output" "bgzip")
  args+=("--no_stats")
  args+=("--fasta" "!{refSeqPath}")
  args+=("--offline")
  args+=("--cache")
  args+=("--dir_cache" "!{params.vcf.annotate.vep_cache_dir}")
  args+=("--species" "homo_sapiens")
  args+=("--assembly" "!{meta.assembly}")
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
  args+=("--buffer_size" "!{params.vcf.annotate.vep_buffer_size}")
  args+=("--fork" "!{task.cpus}")
  args+=("--hgvs")
  args+=("--pubmed")
  args+=("--dir_plugins" "!{params.vcf.annotate.vep_plugin_dir}")
  args+=("--plugin" "Grantham")
  args+=("--plugin" "SpliceAI,snv=!{vepPluginSpliceAiSnvPath},indel=!{vepPluginSpliceAiIndelPath}")
  args+=("--plugin" "Capice,${capiceOutputPath}")
  args+=("--plugin" "UTRannotator,!{vepPluginUtrAnnotatorPath}")
  args+=("--custom" "!{vepCustomPhyloPPath},phyloP,bed,exact,0")
  args+=("--safe")

  if [ -n "!{hpoIds}" ]; then
    args+=("--plugin" "Hpo,!{params.vcf.annotate.vep_plugin_hpo},!{hpoIds.replace(',', ';')}")
  fi
  args+=("--plugin" "Inheritance,!{params.vcf.annotate.vep_plugin_inheritance}")
  if [ -n "!{vepPluginVkglPath}" ] && [ -n "!{params.vcf.annotate.vep_plugin_vkgl_mode}" ]; then
    args+=("--plugin" "VKGL,!{vepPluginVkglPath},!{params.vcf.annotate.vep_plugin_vkgl_mode}")
  fi
  if [ -n "!{vepCustomGnomAdPath}" ]; then
    args+=("--custom" "!{vepCustomGnomAdPath},gnomAD,vcf,exact,0,AF,HN")
  fi
  if [ -n "!{vepCustomClinVarPath}" ]; then
      args+=("--custom" "!{vepCustomClinVarPath},clinVar,vcf,exact,0,CLNSIG,CLNSIGINCL,CLNREVSTAT")
  fi
  if [ -n "!{params.vcf.annotate.annotsv_cache_dir}" ]; then
    # when you change the field also update the empty file header in this file
    args+=("--plugin" "AnnotSV,!{vcf}.tsv,AnnotSV_ranking_score;AnnotSV_ranking_criteria;ACMG_class")
  fi

  ${CMD_VEP} "${args[@]}"
}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main () {
  if [ -n "!{params.vcf.annotate.annotsv_cache_dir}" ]; then
    annot_sv
  fi

  capice
  vep
  index
}

main "$@"