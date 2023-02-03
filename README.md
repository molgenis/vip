# Variant Interpretation Pipeline

This is VIP with added non-coding functionality based on the [GREEN-DB](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8934622/) method. 
It has extra annotations resources which includes:
- TFBS regions (The TF that can bind the region)
- UCNE regions
- DNase regions
- FATHMM-MKL scores
- ReMM scores
- ncER scores

This branch has the annotations that are expected input for the [vip-decision-tree](https://github.com/molgenis/vip-decision-tree/tree/feat/annotation) score annotation branch. This score annotation tool calculates and annotates a variants score based on the added annotations. 

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
