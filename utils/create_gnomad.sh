#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")

APPTAINER_CACHEDIR="put_your_dir_here"
CMD_BCFTOOLS="apptainer exec --no-mount home --bind /groups ${APPTAINER_CACHEDIR}/bcftools-1.19.sif bcftools"
CMD_BGZIP="apptainer exec --no-mount home --bind /groups ${APPTAINER_CACHEDIR}/vep-112.0.sif bgzip"
CMD_TABIX="apptainer exec --no-mount home --bind /groups ${APPTAINER_CACHEDIR}/vep-112.0.sif tabix"

THREADS=4

download_contig () {
  local -r path="${1}"
  local -r version="${2}"
  local -r download_dir="${3}"

  local -r base_url="https://storage.googleapis.com/gcp-public-data--gnomad/release/${version}"
  wget --continue --directory-prefix="${download_dir}" "${base_url}/${path}"
  wget --continue --directory-prefix="${download_dir}" "${base_url}/${path}.tbi"
}

download () {
  local -r version="${1}"
  local -r download_dir="${SCRIPT_DIR}/data"

  local -r path_prefix="vcf/joint/gnomad.joint.v${version}.sites."
  local -r path_postfix=".vcf.bgz"

  mkdir -p "${download_dir}"

  for contig in "${contigs[@]}"; do
    download_contig "${path_prefix}${contig}${path_postfix}" "${version}" "${download_dir}"
  done
}

convert() {
  local -r contig="${1}"
  local -r version="${2}"

  local args_query=()
  args_query+=("query")
  args_query+=("--print-header")
  args_query+=("--format" "%CHROM\t%POS\t%REF\t%ALT\t%AF_exomes\t%AF_genomes\t%AF_joint\t%faf95_exomes\t%faf95_genomes\t%faf95_joint\t%faf99_exomes\t%faf99_genomes\t%faf99_joint\t%nhomalt_exomes\t%nhomalt_genomes\t%nhomalt_joint\t%exomes_filters\t%genomes_filters\t%not_called_in_exomes\t%not_called_in_genomes\t%AN_exomes\t%AN_genomes\t%AN_joint\n")
  args_query+=("${SCRIPT_DIR}/data/gnomad.joint.v${version}.sites.${contig}.vcf.bgz")

  ${CMD_BCFTOOLS} "${args_query[@]}" | \
  awk '
    BEGIN {
      FS=OFS="\t"
    }
    NR==1 {
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20,
        "[21]COV_exomes", "[22]COV_genomes", "[23]COV_joint"
    }
    NR>1 {
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        $1, $2, $3, $4,
        $5!="." ? $5 : "",
        $6!="." ? $6 : "",
        $7!="." ? $7 : "",
        $8!="." ? $8 : "",
        $9!="." ? $9 : "",
        $10!="." ? $10 : "",
        $11!="." ? $11 : "",
        $12!="." ? $12 : "",
        $13!="." ? $13 : "",
        $14!="." ? $14 : "",
        $15!="." ? $15 : "",
        $16!="." ? $16 : "",
        $17!="." ? $17 : "",
        $18!="." ? $18 : "",
        $19!="." ? $19 : "",
        $20!="." ? $20 : "",
        $21!="." ? $21/(730947*2) : "",
        $22!="." ? $22/(76215*2) : "",
        $23!="." ? ($19!="." ? ($20!="." ? $23/((730947+76215)*2) : $23/(730947*2)) : $23/(76215*2)) : ""
    }
  ' > "${SCRIPT_DIR}/intermediates/gnomad.total.v${version}.sites.${contig}.annotated.tsv"
}

concat() {
  local -r version="${1}"
  local -r intermediates_dir="${SCRIPT_DIR}/intermediates"
  mkdir -p "${intermediates_dir}"

  local args=()
  for contig in "${contigs[@]}"; do
    args+=("${intermediates_dir}/gnomad.total.v${version}.sites.${contig}.annotated.tsv")
  done

  local -r output="${SCRIPT_DIR}/gnomad.total.v${version}.sites.stripped.tsv.gz"
  cat "${args[@]}" | ${CMD_BGZIP} --compress-level 9 --threads "${THREADS}" > "${output}"
  ${CMD_TABIX} "${output}" --begin 2 --end 2 --sequence 1 --skip-lines 1
}

main() {
  local -r version="4.1"
  local -r contigs=("chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY")

  # download
  download "${version}"

  # convert
  for contig in "${contigs[@]}"; do
    echo -e "converting ${contig}"
    convert "${contig}" "${version}"
  done

  # concat
  concat "${version}"
}

main "${@}"