# Variant Interpretation Pipeline

## Requirements
- Any modern Linux distribution
- Singularity (see [admin guide](https://sylabs.io/guides/latest/admin-guide/))

## Installation
Run `cd singularity; sudo bash build.sh` to build singularity images.

## Usage
```
usage: pipeline.sh -i <arg>

-i, --input      <arg>    required: Input VCF file (.vcf or .vcf.gz).
-o, --output     <arg>    optional: Output VCF file (.vcf.gz).
-b, --probands   <arg>    optional: Subjects being reported on (comma-separated VCF sample names).
-p, --pedigree   <arg>    optional: Pedigree file (.ped).
-t, --phenotypes <arg>    optional: Phenotypes for input samples.
-s, --start      <arg>    optional: Different starting point for the pipeline (annotate, filter, inheritance or report).

-c, --config     <arg>    optional: Comma separated list of configuration files (.cfg)
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.
-h, --help                optional: Print this message and exit.

config:
  assembly                allowed values: GRCh37, GRCh38 default: GRCh37
  reference               reference sequence file
  cpu_cores               number of CPU cores
  singularity_image_dir   directory where the singularity images are stored.
  preprocess_*            see 'bash pipeline_preprocess.sh --help' for usage.
  annotate_*              see 'bash pipeline_annotate.sh --help' for usage.
  filter_*                see 'bash pipeline_filter.sh --help' for usage.
  inheritance_*           see 'bash pipeline_inheritance.sh --help' for usage.
  report_*                see 'bash pipeline_report.sh --help' for usage.

examples:
  pipeline.sh -i in.vcf
  pipeline.sh -i in.vcf.gz -o out.vcf.gz
  pipeline.sh -i in.vcf.gz -b sample0 -p in.ped -t HP:0000123 -s inheritance
  pipeline.sh -i in.vcf.gz -c config.cfg -f -k
  pipeline.sh -i in.vcf.gz -c config1.cfg,config2.cfg -f -k

examples - probands:
  pipeline.sh -i in.vcf.gz --probands sample0
  pipeline.sh -i in.vcf.gz --probands sample0,sample1

examples - phenotypes:
  pipeline.sh -i in.vcf.gz --phenotypes HP:0000123
  pipeline.sh -i in.vcf.gz --phenotypes HP:0000123;HP:0000234
  pipeline.sh -i in.vcf.gz --phenotypes sample0/HP:0000123
  pipeline.sh -i in.vcf.gz --phenotypes sample0/HP:0000123,sample1/HP:0000234
```

## Usage: modules
Pipeline modules can be used separately, run one of the following scripts for usage information:
```
pipeline_preprocess.sh
pipeline_annotate.sh
pipeline_filter.sh
pipeline_report.sh
```
