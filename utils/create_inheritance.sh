#!/bin/bash

# Retrieve directory containing the collection of scripts (allows using other scripts with & without Slurm).
if [[ -n "${SLURM_JOB_ID}" ]]; then SCRIPT_DIR=$(dirname "$(scontrol show job "${SLURM_JOB_ID}" | awk -F= '/Command=/{print $2}' | cut -d ' ' -f 1)"); else SCRIPT_DIR=$(dirname "$(realpath "$0")"); fi
SCRIPT_NAME="$(basename "$0")"

main() {
  echo -e "downloading ..."
  wget --quiet --continue https://download.molgeniscloud.org/downloads/vip/images/utils/vcf-inheritance-3.0.1.sif
  wget --quiet --continue https://download.molgeniscloud.org/downloads/vip/resources/utils/incomplete_penetrantie_genes_entrez_20210125.tsv
  wget --quiet --continue http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa
  wget --quiet --continue https://research.nhgri.nih.gov/CGD/download/txt/CGD.txt.gz
  echo -e "downloading done"

  # create dummy genemap2.txt
  local geneMapFilePath="genemap2.txt"
  cat >"${geneMapFilePath}" <<EOT
# header line 1
# header line 2
# header line 3
# Chromosome	Genomic	Position	Start	Genomic	Position	End	Cyto	Location	Computed	Cyto	Location	MIM Number	Gene Symbols	Gene Name	Approved Symbol	Entrez Gene ID	Ensembl Gene ID	Comments	Phenotypes	Mouse Gene Symbol/ID
EOT

  local outputPath="inheritance_$(date '+%Y%m%d').tsv"

  local args=()
  args+=("-jar" "/opt/vcf-inheritance/lib/genemap-mapper.jar")
  args+=("-i" "genemap2.txt")
  args+=("-h" "phenotype.hpoa")
  args+=("--incomplete_penetrance" "incomplete_penetrantie_genes_entrez_20210125.tsv")
  args+=("-c" "CGD.txt.gz")
  args+=("-o" "${outputPath}")
  args+=("-f")

  echo -e "creating ${outputPath} ..."
  APPTAINER_BIND="${SCRIPT_DIR}" apptainer exec vcf-inheritance-3.0.1.sif java "${args[@]}"
  echo -e "creating ${outputPath} done"
}

main "${@}"
