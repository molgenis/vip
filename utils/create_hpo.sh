#!/bin/bash
set -euo pipefail

# produce tsv for Hpo.pm VEP plugin
wget http://purl.obolibrary.org/obo/hp/hpoa/phenotype_to_genes.txt
echo -e "#Format: entrez-gene-id<tab>HPO-Term-ID" > "hpo_$(date '+%Y%m%d').tsv"
sed -e 1d phenotype_to_genes.txt | awk -v FS='\t' -v OFS='\t' '{print $3 "\t" $1}' | sort | uniq >> "hpo_$(date '+%Y%m%d').tsv"
