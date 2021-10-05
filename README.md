# Variant Interpretation Pipeline

## Requirements
- Any modern Linux distribution
- Singularity (see [admin guide](https://sylabs.io/guides/latest/admin-guide/))
- \[Windows\] [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/) (f.e. running Ubuntu)
- \[MacOS\] [Vagrant](https://www.vagrantup.com/)
- \[MacOS\] [VirtualBox](https://www.virtualbox.org/) (used by Vagrant)

## Installation
**IMPORTANT:** The `pipeline.sh` (and related) scripts assume several directories being present such as `/apps`. These is currently not configured in the `Vagrantfile` and would require additional configuration in WSL as well.

### Linux/Windows (running WSL)
Run `cd singularity && sudo bash build.sh` to build singularity images.

### MacOS
Run `vagrant up && vagrant ssh` to start and login to the vagrant container.
From here, run `cd /vagrant/singularity/ && sudo bash build.sh` to build the singularity images.

When done, you can exit the Vagrant VM through `exit` and then shut it down with `vagrant halt`.

Note that Vagrant only syncs the current folder. When using data stored elsewhere,
be sure to adjust `config.vm.synced_folder` in the `Vagrantfile`.

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
