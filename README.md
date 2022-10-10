# Variant Interpretation Pipeline

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
bash vip/run_vcf.sh
bash vip/run_gvcf.sh
bash vip/run_cram.sh
bash vip/run_fastq.sh
```
