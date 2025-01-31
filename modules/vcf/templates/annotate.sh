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
  local -r vcf="${1}"
  capice_vep "${vcf}"
  capice_bcftools
  #only run capice if there a variants with annotations, e.g. <STR> only VCF files do not yield any annotated lines
  if [ "$(wc -l < "${capiceInputPath}")" -gt 1 ]; then
    capice_predict
  fi
}

capice_vep() {
  local -r vcf="${1}"

  local args=()
  args+=("--input_file" "${vcf}")
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
  local -r vcf="${1}"
  local -r vcfOut="${2}"

  local args=()
  args+=("--repeats-file" "!{strangerCatalog}")
  args+=("--loglevel" "ERROR")
  args+=("${vcf}")

  ${CMD_STRANGER} "${args[@]}" | ${CMD_BCFTOOLS} view --no-version --threads "!{task.cpus}" --output-type "z" --output-file "${vcfOut}"
}

vep_preprocess() {
  local -r vcf="${1}"
  local -r vcfOut="${2}"

  # use <CNV:TR> symbolic alleles instead of <STR..> to align with VCF v4.4 section 5.6 and enable VEP annotation
  # 1. add CNV:TR ALT header
  # 2. remove STR[number] ALT headers
  # 3. rename <STR[number]> symbolic alleles to <CNV:TR>
  echo -e '##ALT=<ID=CNV:TR,Description="Tandem repeat determined based on DNA abundance">' > vcf_header_cnv-tr.txt
  ${CMD_BCFTOOLS} annotate --header-lines vcf_header_cnv-tr.txt --no-version --threads "!{task.cpus}" "${vcf}" | \
    sed '/^##ALT=<ID=STR[0-9]\+,/d' | \
    sed 's/<STR[0-9]\+>/<CNV:TR>/g' | \
    ${CMD_BCFTOOLS} view --no-version --threads "!{task.cpus}" --output-type "z" --output-file "${vcfOut}"
}

vep() {
  local -r vcf="${1}"

  local args=()
  args+=("--input_file" "${vcf}")
  args+=("--format" "vcf")
  args+=("--output_file" "vep_!{vcfOut}")
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
  args+=("--custom" "!{vepCustomPhyloPPath},phyloP,bigwig,exact,0")
  args+=("--safe")

  if [ -n "!{hpoIds}" ]; then
    args+=("--plugin" "Hpo,!{params.vcf.annotate.vep_plugin_hpo},!{hpoIds.replace(',', ';')}")
  fi
  if [ -n "!{gadoScores}" ]; then
    args+=("--plugin" "GADO,!{gadoScores},!{params.vcf.annotate.ensembl_gene_mapping}")
  fi
  args+=("--plugin" "Inheritance,!{params.vcf.annotate.vep_plugin_inheritance}")
  if [ -n "!{vepPluginVkglPath}" ] && [ -n "!{params.vcf.annotate.vep_plugin_vkgl_mode}" ]; then
    args+=("--plugin" "VKGL,!{vepPluginVkglPath},!{params.vcf.annotate.vep_plugin_vkgl_mode}")
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
  if [ -n "!{vepPluginGreenDbPath}" ] && [ "!{vepPluginGreenDbEnabled}" = true  ]; then
    args+=("--plugin" "GREEN_DB,!{vepPluginGreenDbPath}")
  fi
  
  ${CMD_VEP} "${args[@]}"
}

#replace with bcftools fill-tags when https://github.com/samtools/bcftools/issues/2338 is resolved
viab(){
  local -r input="${1}"

  zcat "${input}" | awk 'BEGIN{FS=OFS="\t"}
    # Skip header lines
    /^##/ { print; next }
    /^#/ { print "##FORMAT=<ID=VIAB,Number=1,Type=Float,Description=\"VIP calculated allele balance\">"; print; next }
    {
      # Extract the FORMAT column and samples
      split($9, format_fields, ":");
      # Check if AD exists in FORMAT
      ad_index = -1;
      for (i = 1; i <= length(format_fields); i++) {
        if (format_fields[i] == "AD") {
          ad_index = i;
          break;
        }
      }
      if(ad_index != -1){
        # append AB to the FORMAT column
        $9 = $9":VIAB";
        # Start at column 10, first sample in the vcf, and increment until the end of line
        for (sample = 10; sample <= NF; sample++) {
          split($sample, sample_fields, ":");
          split(sample_fields[ad_index], ad_values, ",");
          
          # Calculate allele balance (VIAB)
          if (length(ad_values) == 2) {
            allele1_depth = ad_values[1]
              total_depth = ad_values[1] + ad_values[2];
              if (total_depth > 0) {
                viab = allele1_depth / total_depth;
              }
              else {
                viab = ".";
              }
          } else {
              viab = ".";
          }
          # Add missing values for trailing missing values
          trailing = length(sample_fields) - length(format_fields)
          for(j = 0; j < trailing; j++){
            $sample = $sample ":.";
          }
          # append VIAB to the sample FORMAT values
          $sample = $sample ":" viab;
        }
      }
      print
    }' | ${CMD_BGZIP} -c > "!{vcfOut}"

}

index () {
  ${CMD_BCFTOOLS} index --csi --output "!{vcfOutIndex}" --threads "!{task.cpus}" "!{vcfOut}"
  ${CMD_BCFTOOLS} index --stats "!{vcfOut}" > "!{vcfOutStats}"
}

main () {
  if [ -n "!{params.vcf.annotate.annotsv_cache_dir}" ]; then
    annot_sv
  fi


  local vepInputPath=""
  if [ -n "!{strangerCatalog}" ]; then
    stranger "!{vcf}" "stranger_!{vcf}"
    vepInputPath="stranger_!{vcf}"
  else
    vepInputPath="!{vcf}"
  fi

  local -r vcfPreprocessed="preprocessed_${vepInputPath}"
  vep_preprocess "${vepInputPath}" "${vcfPreprocessed}"
  capice "${vcfPreprocessed}"
  vep "${vcfPreprocessed}"
  
  viab "vep_!{vcfOut}"
  index
}

main "$@"
