# Command-line options
The `vip` command takes input vcf/cram/fastq data and produces a filtered annotated `.vcf.gz` containing candidate variants of interest.

In addition to the `.vcf.gz` an interactive `.html` report is produced that can be displayed in any modern web browser. 

`vip --help` prints the available command-line options: 

```
usage: vip -w <arg> -i <arg> -o <arg>
  -w, --workflow <arg>  workflow to execute. allowed values: cram, fastq, vcf
  -i, --input    <arg>  path to sample sheet .tsv
  -o, --output   <arg>  output folder
  -c, --config   <arg>  path to additional nextflow .cfg (optional)
  -p, --profile  <arg>  nextflow configuration profile (optional)
  -r, --resume          resume execution using cached results (default: false)
  -h, --help            print this message and exit
```

## Required
- `workflow` as described [here](workflow.md)
- `input` as described [here](input.md)
- `output` as described [here](output.md)

## Optional
- `config` as described [here](config.md)
- `profile` the configuration profile to use. allowed values are `local`, `slurm` plus any profiles added in `--config`   
- `resume` useful to continue executions that was stopped by an error using cached results

## Defaults
By default `vip`:

- Assumes an Illumina sequencing platform was used to generate the input data
- Assumes whole-genome sequencing (WGS) method was used to generate the input data
- Uses a GRCh38 reference genome ([GCA_000001405.15 / GCF_000001405.26](https://www.ncbi.nlm.nih.gov/assembly/GCF_000001405.26/))
- Provides classification trees for default variant filtration. For details, see [here](../advanced/classification_trees.md)
- Creates reports using a default report template. For details, see [here](../advanced/report_templates.md)
