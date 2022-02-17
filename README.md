# Variant Interpretation Pipeline

## Requirements
- [Nextflow](https://www.nextflow.io/)
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
NXF_VER="21.10.6" nextflow run vip/main.nf \
  --assembly <GRCh37 or GRCh38> \
  --input <path> \
  --output <path>
```
See [nextflow.config](https://github.com/molgenis/vip/blob/master/nextflow.config) for additional parameters.

### License
Some tools and resources have licenses that restrict their usage: 
- [AnnotSV](https://lbgi.fr/AnnotSV/) (GPL-3.0 License)
- [gnomAD](https://gnomad.broadinstitute.org/) (CC0 1.0 license)
- [SpliceAI](https://basespace.illumina.com/s/otSPW8hnhaZR) (free for academic and not-for-profit use)
- [VKGL](https://vkgl.molgeniscloud.org/) (CC BY-NC-SA 4.0 license)

Update [nextflow.config](https://github.com/molgenis/vip/blob/master/nextflow.config) to prevent their usage.