# Variant Interpretation Pipeline
VIP is a flexible human variant interpretation pipeline for rare disease using state-of-the-art pathogenicity prediction ([CAPICE](https://github.com/molgenis/capice)) and template-based interactive reporting to facilitate decision support.

## Content
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Start from fastq](#usage-fastq)
  - [Start from bam or cram](#usage-cram)
  - [Start from gVcf](#usage-gvcf)
  - [Start from vcf](#usage-vcf)
- [Configuration](#configuration)
  - [Classification Tree](#classification-tree)
  - [Report Template](#report-template)
- [Examples](#examples)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Introduction
TODO

## Prerequisites
- POSIX compatible system (Linux, OS X, etc) / Windows through [WSL](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)
- Bash 3.2 (or later)
- Java 11 or later
- [Apptainer](https://apptainer.org)
  - including the apptainer-suid component ([Documentation](https://github.com/apptainer/apptainer/blob/main/INSTALL.md))
- 300GB disk space

## Installation
```
git clone https://github.com/molgenis/vip
bash vip/install.sh
```
By default, the installation script downloads resources for both GRCh37 and GRCh38 assemblies.
Use `--assembly` to download recourses for a specific assembly:
```
bash vip/install.sh --assembly GRCh37
```
```
bash vip/install.sh --assembly GRCh38
```

## Usage
TODO

## Configuration
TODO

### Classification Tree
TODO

### Report Template
TODO

## Examples
TODO

## License
TODO

## Acknowledgements
Standing on the shoulders of giants. This project could not have possible without the existence of many other tools and resources. Among them we would like to thank the people behind the following projects:
- [Ensembl Variant Effect Predictor (VEP)](https://grch38.ensembl.org/info/docs/tools/vep/index.html)
- [Nextflow](https://www.nextflow.io/)
- [AnnotSV](https://lbgi.fr/AnnotSV/)
- [Illumina SpliceAI](https://github.com/Illumina/SpliceAI)
- [igv.js](https://github.com/igvteam/igv.js)