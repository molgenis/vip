# Variant Interpretation Pipeline
VIP is a flexible human variant interpretation pipeline for rare disease using state-of-the-art pathogenicity prediction ([CAPICE](https://github.com/molgenis/capice)) and template-based interactive reporting to facilitate decision support.

![Example Report](docs/img/report_example.png)

## Documentation
VIP documentation is available at this link https://molgenis.github.io/vip/.

## Quick Reference

### Requirements
- Java
- [Apptainer](https://apptainer.org/docs/admin/main/installation.html#install-from-pre-built-packages)
- 400GB free disk space

### Installation
```bash
git clone https://github.com/molgenis/vip
bash vip/install.sh
```

### Usage
```bash
usage: vip -w <arg> -i <arg> -o <arg>
  -w, --workflow <arg>  workflow to execute. allowed values: cram, fastq, vcf
  -i, --input    <arg>  path to sample sheet .tsv
  -o, --output   <arg>  output folder
  -c, --config   <arg>  path to additional nextflow .cfg (optional)
  -p, --profile  <arg>  nextflow configuration profile (optional)
  -r, --resume          resume execution using cached results (default: false)
  -h, --help            print this message and exit
```

## Developers
To create the documentation pages:
```
pip install mkdocs mkdocs-mermaid2-plugin
mkdocs serve
```

To publish the documentation pages:
```
mkdocs gh-pages
```