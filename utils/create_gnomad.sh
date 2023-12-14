#!/bin/bash
APPTAINER_CACHEDIR="put_your_dir_here"
CMD_BCFTOOLS="apptainer exec --no-mount home bcftools-1.18-patched.sif bcftools"
CMD_BGZIP="apptainer exec --no-mount home --bind /groups ${APPTAINER_CACHEDIR}/vep-109.3.sif bgzip"
CMD_TABIX="apptainer exec --no-mount home --bind /groups ${APPTAINER_CACHEDIR}/vep-109.3.sif tabix"

THREADS=4

download () {
  local -r path="${1}"

  local -r base_url="https://storage.googleapis.com/gcp-public-data--gnomad/release/4.0"
  wget --continue "${base_url}/${path}"
  wget --continue "${base_url}/${path}.tbi"
}

download_exomes () {
  local -r path_prefix="vcf/exomes/gnomad.exomes.v4.0.sites.chr"
  local -r path_postfix=".vcf.bgz"

  for i in {1..22}; do
    download "${path_prefix}${i}${path_postfix}"
  done
  download "${path_prefix}X${path_postfix}"
  download "${path_prefix}Y${path_postfix}"
}

download_genomes () {
  local -r path_prefix="vcf/genomes/gnomad.genomes.v4.0.sites.chr"
  local -r path_postfix=".vcf.bgz"
  for i in {1..22}; do
    download "${path_prefix}${i}${path_postfix}"
  done
  download "${path_prefix}X${path_postfix}"
  download "${path_prefix}Y${path_postfix}"
}

annotate() {
  local -r method="${1}"
  local -r contig="${2}"

  local args=()
  args+=("annotate")
  args+=("--no-version")
  args+=("--remove" "ID,QUAL,^INFO/AF,INFO/AF_joint,INFO/AN,INFO/AN_joint,INFO/nhomalt,INFO/nhomalt_joint,INFO/faf95,INFO/faf95_joint,INFO/faf99,INFO/faf99_joint")
  args+=("--rename-annots" "gnomad_rename_${method}.txt")
  args+=("--columns-file" "gnomad_columns_${method}.txt")
  args+=("--output-type" "b")
  args+=("--output" "intermediates/gnomad.${method}.v4.0.sites.${contig}.annotated.bcf.bgz")
  args+=("--threads" "${THREADS}")
  args+=("--write-index")
  args+=("data/gnomad.${method}.v4.0.sites.${contig}.vcf.bgz")

  ${CMD_BCFTOOLS} "${args[@]}"
}

merge() {
  local contig="${1}"

  local args_merge=()
  args_merge+=("merge")
  args_merge+=("--no-version")
  args_merge+=("--merge" "none")
  args_merge+=("--no-index")
  args_merge+=("--threads" "${THREADS}")
  args_merge+=("intermediates/gnomad.exomes.v4.0.sites.${contig}.annotated.bcf.bgz")
  args_merge+=("intermediates/gnomad.genomes.v4.0.sites.${contig}.annotated.bcf.bgz")

  local args_query=()
  args_query+=("query")
  args_query+=("--print-header")
  args_query+=("--format" "%CHROM\t%POS\t%REF\t%ALT\t%AF_E\t%AF_G\t%AF_T\t%FAF95_E\t%FAF95_G\t%FAF95_T\t%FAF99_E\t%FAF99_G\t%FAF99_T\t%HN_E\t%HN_G\t%HN_T\t%QC_E\t%QC_G\t%AN_E\t%AN_G\t%AN_T\n")

  ${CMD_BCFTOOLS} "${args_merge[@]}" | ${CMD_BCFTOOLS} "${args_query[@]}" | \
  awk '
    BEGIN {
      FS=OFS="\t"
    }
    NR==1 {
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18,
        "[19]COV_E", "[20]COV_G", "[21]COV_T"
    }
    NR>1 {
      printf "%s\t%s\t%s\t%s\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%0.3f\t%s\t%s\t%s\t%s\t%s\t%0.3f\t%0.3f\t%0.3f\n",
        $1, $2, $3, $4,
        $5!="." ? ($5!="0" ? $5 : "+inf") : "+nan",
        $6!="." ? ($6!="0" ? $6 : "+inf") : "+nan",
        $7!="." ? ($7!="0" ? $7 : "+inf") : "+nan",
        $8!="." ? ($8!="0" ? $8 : "+inf") : "+nan",
        $9!="." ? ($9!="0" ? $9 : "+inf") : "+nan",
        $10!="." ? ($10!="0" ? $10 : "+inf") : "+nan",
        $11!="." ? ($11!="0" ? $11 : "+inf") : "+nan",
        $12!="." ? ($12!="0" ? $12 : "+inf") : "+nan",
        $13!="." ? ($13!="0" ? $13 : "+inf") : "+nan",
        $14!="." ? $14 : "",
        $15!="." ? $15 : "",
        $16!="." ? $16 : "",
        $17!="." ? $17 : "NO_VAR",
        $18!="." ? $18 : "NO_VAR",
        $19!="." ? $19/(730947*2) : "+nan",
        $20!="." ? $20/(76215*2) : "+nan",
        $21!="." ? ($17!="." ? ($18!="." ? $21/((730947+76215)*2) : $21/(730947*2)) : $21/(76215*2)) : "+nan"
    }
  ' | \
  awk '
    BEGIN {
      FS=OFS="\t"
    }
    NR==1 {
      print
    }
    NR>1 {
      $5 = $5!="nan" ? ($5!="inf" ? $5 : 0) : "";
      $6 = $6!="nan" ? ($6!="inf" ? $6 : 0) : "";
      $7 = $7!="nan" ? ($7!="inf" ? $7 : 0) : "";
      $8 = $8!="nan" ? ($8!="inf" ? $8 : 0) : "";
      $9 = $9!="nan" ? ($9!="inf" ? $9 : 0) : "";
      $10 = $10!="nan" ? ($10!="inf" ? $10 : 0) : "";
      $11 = $11!="nan" ? ($11!="inf" ? $11 : 0) : "";
      $12 = $12!="nan" ? ($12!="inf" ? $12 : 0) : "";
      $13 = $13!="nan" ? ($13!="inf" ? $13 : 0) : "";
      $19 = $19!="nan" ? $19 : "";
      $20 = $20!="nan" ? $20 : "";
      $21 = $21!="nan" ? $21 : "";
      print
    }
  ' > "intermediates/gnomad.total.v4.0.sites.${contig}.annotated.tsv"
}

concat() {
  local args=()
  for contig in "${contigs[@]}"; do
    args+=("intermediates/gnomad.total.v4.0.sites.${contig}.annotated.tsv")
  done

  local -r output=gnomad.total.v4.sites.stripped.tsv.gz
  cat "${args[@]}" | ${CMD_BGZIP} --compress-level 9 --threads "${THREADS}" > "${output}"
  ${CMD_TABIX} "${output}" --begin 2 --end 2 --sequence 1 --skip-lines 1
}

main() {
  local -r methods=("exomes" "genomes")
  local -r contigs=("chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY")

  # download
  download_exomes
  download_genomes

  # annotate
  for contig in "${contigs[@]}"; do
    for method in "${methods[@]}"; do
      echo -e "annotating ${method} ${contig}"
      annotate "${method}" "${contig}"
    done
  done

  # merge
  for contig in "${contigs[@]}"; do
    echo -e "merging ${contig}"
    merge "${contig}"
  done

  # concat
  concat
}

main "${@}"