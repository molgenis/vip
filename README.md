# Variant Interpretation Pipeline

This is VIP with added non-coding functionality based on the [GREEN-DB](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8934622/) method. 
It has extra annotations resources which includes:
- TFBS regions (The TF that can bind the region)
- UCNE regions
- DNase regions
- FATHMM-MKL scores
- ReMM scores
- ncER scores
- GREEN-DB constraint values 
- HPO phenotypes

This branch has the annotations that are expected input for the [vip-decision-tree](https://github.com/molgenis/vip-decision-tree/tree/feat/annotation) score annotation branch. This score annotation tool calculates and annotates a variants score based on the added annotations. 

These added annotations require resources that are not downloaded by the install.sh and need to be downloaded manually. 
They can be downloaden from the [GREEN-DB download website](https://green-varan.readthedocs.io/en/latest/Download.html). The downloaded resources require some preprocessing follow the following steps for each annotation resource:

[BCFtools](https://samtools.github.io/bcftools/) is required te perform the pre processing steps

## TFBS/ncER


File: {Build}_ncER_perc.bed.gz
File: {Build}_TFBS_merged.bed.gz

Unpack the downloaded gz files and follow these steps:

```
grep -v "#" file.bed  | sort -k1,1 -k2,2n -k3,3n -t$'\t' | bgzip -c > file.bed.gz
tabix -p bed file.bed.gz
```

## UCNE/DNase

File: {Build}_UCNE.bed.gz
File: {Build}_DNase_merged.bed.gz

unpack the downloaded gz files and follow these steps:

Perform this extra step for the **DNase** and **UCNE** file to add a fourth column.
Unpack the file and perform this step:

```
awk 'BEGIN{ FS = OFS = "\t" } { print $1,$2,$3, (NR==1? "id" : "UCNE") }' {Build}_UCNE.bed > tmp && mv tmp GRCh38_UCNE.bed 

awk 'BEGIN{ FS = OFS = "\t" } { print $1,$2,$3, (NR==1? "id" : "DNase") }' {Build}_DNase.merged.bed > tmp && mv tmp GRCh37_DNase.bed
```

And then for both files:
```
grep -v "#" file.bed  | sort -k1,1 -k2,2n -k3,3n -t$'\t' | bgzip -c > file.bed.gz
tabix -p bed file.bed.gz
```

## GREEN-DB constraint value

File: {build}_GREEN-DB.bed.gz

Unpack the downloaded gz files and follow these steps:
Or use this [script](https://github.com/JonathanKlimp/Graduation-scripts/blob/main/data_conversion_scripts/process_bed_constraint_VEP.sh)

First step is to remove all unused columns so that only the constraint value remains.
Second step removes all values smaller than 0.7 and NA values.
```
cut -f 1,2,3,9 {Build}_GREEN-DB.bed > tmp.txt                          

awk '$4 > 0.7 && $4 != "NA"' tmp.txt > {Build}_GREEN-DB-constraint.bed 

grep -v "#" file.bed  | sort -k1,1 -k2,2n -k3,3n -t$'\t' | bgzip -c > file.bed.gz
tabix -p bed file.bed.gz
```

## ReMM

File: {Build}_ReMM.tsv.gz

Perform these steps:

```
gunzip {Build}_ReMM.tsv.gz

awk 'BEGIN{ FS = OFS = "\t" } { print $1,$2,$2,$3 }' {Build}_ReMM.tsv > {Build}_ReMM_new_column.bed
#grep -v "#" {Build}_ReMM_new_column.bed | sort -k1,1 -k2,2n -k3,3n -t$'\t' | bgzip -c > {Build}_ReMM.bed.gz
tabix -p bed {Build}_ReMM.bed.gz

```

## FATHMM-MKL

File: {Build}_FATHMM_MKL.tsv.gz

Use this script to convert the tsv file to vcf format: [conversion script](https://github.com/JonathanKlimp/Graduation-scripts/blob/main/data_conversion_scripts/convert_score_tsv_to_vcf.sh)

## Phenotyepes

File: GREEN-DB_v2.5.db.gz

Extract the HPO phenotypes table and the table with the regions from the DB file using [SQLite](https://sqlite.org/index.html) or another preferred DB browser.

Once extracted perform the following:
This command checks if an ID is matched in both files. If this is the case the chrom, pos, stop, phenotype and phenotypeID are printed to a new file.

```
awk -v FS='\t' -v OFS='\t' 'FNR==NR{a[$4]=$1 FS $2 FS $3;next} ($1 in a) {print a[$1],$3,$4}' GREEN-DB_{Build}_regions.csv GREEN-DB_phenotypes.csv > GREEN_DB_{Build}_region_phenos.bed
```

Then perform the following command:

```
grep -v "#" GREEN_DB_{Build}_region_phenos.bed | sort -k1,1 -k2,2n -k3,3n -t$'\t' | bgzip -c > GREEN_DB_{Build}_region_phenos.bed.gz
tabix -p bed GREEN_DB_{Build}_region_phenos.bed
```

## Requirements
- POSIX compatible system (Linux, OS X, etc) / Windows through [WSL](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)
- Bash 3.2 (or later)
- Java 11 or later
- [Singularity](https://sylabs.io/singularity/)
- 300GB disk space

## Installation
```
git clone https://github.com/molgenis/vip
bash vip/install.sh
```
### Assembly
By default, the installation script downloads resources for the GRCh37 and GRCh38 assemblies.
Use `--assembly` to download recourses for a specific assembly:  
```
bash vip/install.sh --assembly GRCh38
```

## Usage
```
vip/nextflow run vip/main.nf \
  --assembly <GRCh37 or GRCh38> \
  --input <path> \
  --output <path>
```
See [nextflow.config](https://github.com/molgenis/vip/blob/main/nextflow.config) for additional parameters.

### License
Some tools and resources have licenses that restrict their usage: 
- [AnnotSV](https://lbgi.fr/AnnotSV/) (GPL-3.0 License)
- [gnomAD](https://gnomad.broadinstitute.org/) (CC0 1.0 license)
- [SpliceAI](https://basespace.illumina.com/s/otSPW8hnhaZR) (free for academic and not-for-profit use)
- [VKGL](https://vkgl.molgeniscloud.org/) (CC BY-NC-SA 4.0 license)
