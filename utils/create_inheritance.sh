#!/bin/bash
set -euo pipefail

wget https://github.com/molgenis/vip-inheritance/releases/download/v1.0.0/genemap-mapper.jar
wget http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa
wget https://research.nhgri.nih.gov/CGD/download/txt/CGD.txt.gz

# create dummy genemap2.txt
geneMapFilePath="genemap2.txt"
  cat >"${geneMapFilePath}" <<EOT
# header line 1
# header line 2
# header line 3
# Chromosome	Genomic	Position	Start	Genomic	Position	End	Cyto	Location	Computed	Cyto	Location	MIM Number	Gene Symbols	Gene Name	Approved Symbol	Entrez Gene ID	Ensembl Gene ID	Comments	Phenotypes	Mouse Gene Symbol/ID
EOT

module load Java
java -jar genemap-mapper.jar -i genemap2.txt -h phenotype.hpoa -c CGD.txt.gz -o inheritance_$(date '+%Y%m%d').tsv -f
module purge
