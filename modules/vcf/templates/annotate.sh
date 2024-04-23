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
  args+=("-genomeBuild" "!{assembly}")
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
  elif [[ "!{assembly}" == "GRCh38" ]]; then
    # workaround for https://github.com/lgmgeo/AnnotSV/issues/152 that might fail for some chromosomes e.g. GRCh37 MT maps to GRCh38 chrM)
    mv "!{vcf}.tsv" "!{vcf}.tsv.tmp"
    awk -v FS='\t' -v OFS='\t' 'NR>1 {$2 = "chr"$2} 1' "!{vcf}.tsv.tmp" > "!{vcf}.tsv"
  fi
}

capice() {
  capice_vep
  capice_bcftools
  #only run capice if there a variants with annotations, e.g. <STR> only VCF files do not yield any annotated lines
  if [ "$(wc -l < "${capiceInputPath}")" -gt 1 ]; then
    capice_predict
  fi
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
  args+=("--assembly" "!{assembly}")
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
  args+=("--custom" "!{vepCustomPhyloPPath},phyloP,bigwig,exact,0")
  args+=("--plugin" "gnomAD,!{vepPluginGnomAdPath}")

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

stranger() {
    cp "!{vcfOut}" stranger_input.vcf.gz

    local args=()
    args+=("--repeats-file" "!{strangerCatalog}")
    args+=("--loglevel" "ERROR")
    args+=("stranger_input.vcf.gz")
    
    ${CMD_STRANGER} "${args[@]}" | ${CMD_BCFTOOLS} view --no-version --threads "!{task.cpus}" --output-type "z" --output-file "!{vcfOut}"
    rm "stranger_input.vcf.gz"
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
  args+=("--assembly" "!{assembly}")
  #args+=("--refseq")
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
  args+=("--plugin" "Capice,${capiceOutputPath},!{params.vcf.annotate.ensembl_gene_mapping}")
  args+=("--plugin" "UTRannotator,!{vepPluginUtrAnnotatorPath}")
  args+=("--custom" "!{vepCustomPhyloPPath},phyloP,bigwig,exact,0")
  args+=("--safe")

  if [ -n "!{hpoIds}" ]; then
    args+=("--plugin" "Hpo,!{params.vcf.annotate.vep_plugin_hpo},!{hpoIds.replace(',', ';')},!{params.vcf.annotate.ensembl_gene_mapping}")
  fi
  if [ -n "!{gadoScores}" ]; then
    args+=("--plugin" "GADO,!{gadoScores},!{params.vcf.annotate.ensembl_gene_mapping}")
  fi
  if [ -n "!{gtexFile}" ]; then
    echo !{tissues}
    args+=("--plugin" "GTEx,!{gtexFile},!{tissues.replace(',', ';')}")
  fi
  args+=("--plugin" "Inheritance,!{params.vcf.annotate.vep_plugin_inheritance},,!{params.vcf.annotate.ensembl_gene_mapping}")
  if [ -n "!{vepPluginVkglPath}" ] && [ -n "!{params.vcf.annotate.vep_plugin_vkgl_mode}" ]; then
    args+=("--plugin" "VKGL,!{vepPluginVkglPath},!{params.vcf.annotate.vep_plugin_vkgl_mode},!{params.vcf.annotate.ensembl_gene_mapping}")
  fi
  if [ -n "!{vepPluginGnomAdPath}" ]; then
    args+=("--plugin" "gnomAD,!{vepPluginGnomAdPath}")
  fi
  if [ -n "!{vepPluginClinVarPath}" ]; then
      args+=("--plugin" "ClinVar,!{vepPluginClinVarPath}")
  fi
  if [ -n "!{params.vcf.annotate.annotsv_cache_dir}" ]; then
    # when you change the field also update the empty file header in this file
    args+=("--plugin" "AnnotSV,!{vcf}.tsv,AnnotSV_ranking_score;AnnotSV_ranking_criteria;ACMG_class")
  fi
  if [ -n "!{alphScorePath}" ]; then
    args+=("--plugin" "AlphScore,!{alphScorePath}")
  fi
  if [ -n "!{vepPluginNcerPath}" ]; then
    args+=("--plugin" "ncER,!{vepPluginNcerPath}")
  fi
  if [ -n "!{fathmmMKLScoresPath}" ]; then
    args+=("--plugin" "FATHMM_MKL_NC,!{fathmmMKLScoresPath}")
  fi
  if [ -n "!{reMMScoresPath}" ]; then
    args+=("--plugin" "ReMM,!{reMMScoresPath}")
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
  if [ -n "!{strangerCatalog}" ]; then
    stranger
  fi
  index
}

main "$@"
