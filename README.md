# Variant Interpretation Pipeline
VIP is a flexible human variant interpretation pipeline for rare disease using state-of-the-art pathogenicity prediction ([CAPICE](https://github.com/molgenis/capice)) and template-based interactive reporting to facilitate decision support.

## Content
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Workflow](#workflow)
  - [Input](#input)
    - [Input VCF](#input-vcf)
    - [Input gVCF](#input-gvcf)
    - [Input CRAM](#input-cram)
    - [Input FASTQ](#input-fastq)
  - [Profile](#profile)
  - [Config](#config)
- [Configuration](#configuration)
  - [Classification Tree](#classification-tree)
  - [Report Template](#report-template)
- [Examples](#examples)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Introduction
<mark>TODO</mark>

## Prerequisites
- [POSIX compatible system](https://en.wikipedia.org/wiki/POSIX#POSIX-oriented_operating_systems) (e.g. Linux, macOS, [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about))
- Bash ≥ 3.2
- Java ≥ 11
- [Apptainer](https://apptainer.org/docs/admin/main/installation.html#install-from-pre-built-packages) (setuid installation)
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
bash vip/install.sh --assembly GRCh38
```

## Usage
```
usage: vip [-w <arg> -i <arg> -o <arg>]
  -w, --workflow <arg>  workflow to execute. allowed values: vcf, gvcf, cram, fastq
  -i, --input    <arg>  path to sample sheet .tsv
  -o, --output   <arg>  output folder
  -a, --assembly <arg>  genome assembly. allowed values: GRCh37, GRCh38 (optional)
  -p, --profile  <arg>  nextflow configuration profile (optional)
  -c, --config   <arg>  path to additional nextflow .cfg (optional)
  -h, --help            print this message and exit
```  
<mark>TODO</mark>

### Workflow
<mark>TODO</mark>

### Input
| column            | type            | required |                                |
|-------------------|-----------------|----------|--------------------------------|
| ``project_id``    | ``string``      |          | default:vip                    |
| ``family_id``     | ``string``      |          | default:vip_fam&#60;index&#62; |
| ``individual_id`` | ``string``      | yes      |                                |
| ``paternal_id``   | ``string``      |          |                                |
| ``maternal_id``   | ``string``      |          |                                |
| ``sex``           | ``enum``        |          | values: [male,female]          |
| ``affected``      | ``boolean``     |          |                                |
| ``proband``       | ``boolean``     |          |                                |
| ``hpo_ids``       | ``string list`` |          | regex: /HP:\d{7}/              |

#### Input VCF
| column  | type     | required |                                        |
|---------|----------|----------|----------------------------------------|
| ``vcf`` | ``file`` |          | file extensions: [.vcf.gz, .vcf, .bcf] |

#### Input gVCF
| column    | type     | required |                                      |
|-----------|----------|----------|--------------------------------------|
| ``g_vcf`` | ``file`` |          | file extensions: [.g.vcf.gz, .g.vcf] |

#### Input CRAM
| column   | type     | required |                              |
|----------|----------|----------|------------------------------|
| ``cram`` | ``file`` |          | file extensions: [cram, bam] |

#### Input FASTQ
| column       | type          | required |                                               |
|--------------|---------------|----------|-----------------------------------------------|
| ``fastq_r1`` | ``file list`` |          | file extensions: [fastq, fastq.gz, fq, fq.gz] |
| ``fastq_r2`` | ``file list`` |          | file extensions: [fastq, fastq.gz, fq, fq.gz] |

### Profile
By default, VIP detects whether [Slurm](https://slurm.schedmd.com/) is available on the system and use the <code>slurm</code> profile. Otherwise, the <code>local</code> profile is used which executes the workflow on this machine. You can override the profile or refer to a custom profile specified in your <code>--config</code>.

Examples:
```
--profile local
--profile slurm
--profile my_profile_defined_in_my_nextflow_cfg
```

### Config
By default, VIP contains configuration that will allow all workflows to run on any machine assuming:
- Whole Genome Sequencing (WGS) input data
- GRCh38 reference genome ([GCA_000001405.15 / GCF_000001405.26](https://www.ncbi.nlm.nih.gov/assembly/GCF_000001405.26/))

An additional configuration file can be provided to override defaults:
```
--config my_nextflow.cfg
```

| param                         | default                                                                                   |                                |
|-------------------------------|-------------------------------------------------------------------------------------------|--------------------------------|
| ``assembly``                  | ``GRCh38``                                                                                | allowed values: GRCh37, GRCh38 | 
| ``sequencingMethod``          | ``WGS``                                                                                   | allowed values: WES, WGS       |
| ``GRCh37.reference.fasta``    | ``${projectDir}/resources/GRCh37/human_g1k_v37.fasta.gz``                                 ||
| ``GRCh37.reference.fastaFai`` | ``${projectDir}/resources/GRCh37/human_g1k_v37.fasta.gz.fai``                             ||
| ``GRCh37.reference.fastaGzi`` | ``${projectDir}/resources/GRCh37/human_g1k_v37.fasta.gz.gzi``                             ||
| ``GRCh38.reference.fasta``    | ``${projectDir}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz``     ||
| ``GRCh38.reference.fastaFai`` | ``${projectDir}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.fai`` ||
| ``GRCh38.reference.fastaGzi`` | ``${projectDir}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.gzi`` ||

For the full list, see [config/nxf.config](https://github.com/molgenis/vip/tree/main/config/nxf.config)

#### Config VCF
For the full list, see [config/nxf_vcf.config](https://github.com/molgenis/vip/tree/main/config/nxf_vcf.config)

#### Config gVCF
For the full list, see [config/nxf_gvcf.config](https://github.com/molgenis/vip/tree/main/config/nxf_gvcf.config)

#### Config CRAM
For the full list, see [config/nxf_cram.config](https://github.com/molgenis/vip/tree/main/config/nxf_cram.config)

#### Config FASTQ
| param                         | default                                                                                   |     |
|-------------------------------|-------------------------------------------------------------------------------------------|-----|
| ``GRCh37.reference.fastaMmi`` | ``${projectDir}/resources/GRCh37/human_g1k_v37.fasta.gz.mmi``                             ||
| ``GRCh38.reference.fastaMmi`` | ``${projectDir}/resources/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz.mmi`` ||

For the full list, see [config/nxf_fastq.config](https://github.com/molgenis/vip/tree/main/config/nxf_fastq.config)

## Configuration
<mark>TODO</mark>

### Classification Tree
<mark>TODO</mark>

### Report Template
<mark>TODO</mark>

## Examples
<mark>TODO</mark>

## License
VIP is released under the [LGPL-3.0 license](https://www.gnu.org/licenses/lgpl-3.0.en.html).

## Acknowledgements
Standing on the shoulders of giants. This project could not have possible without the existence of many other tools and resources. Among them we would like to thank the people behind the following projects:
- [Ensembl Variant Effect Predictor (VEP)](https://grch38.ensembl.org/info/docs/tools/vep/index.html)
- [Nextflow](https://www.nextflow.io/)
- [AnnotSV](https://lbgi.fr/AnnotSV/)
- [Illumina SpliceAI](https://github.com/Illumina/SpliceAI)
- [igv.js](https://github.com/igvteam/igv.js)