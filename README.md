# Variant Interpretation Pipeline

## Installation
The [capice2vcf jar](https://github.com/molgenis/capice) must be present in the root directory of the pipeline.

## Usage
```
usage: pipeline.sh -i <arg> -o <arg> [-p <arg>] [-f] [-d] [-k]

-i, --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o, --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-p, --pedigree <arg>      optional: Pedigree file (.ped).
-t, --phenotypes <arg>    optional: Phenotypes for input samples (see examples).
-f, --force               optional: Override the output file if it already exists.
-d, --debug               optional: Enable debug logging.
-k, --keep                optional: Keep intermediate files.

examples:
  pipeline.sh -i in.vcf -o out.vcf
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -p in.ped
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HPO:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HPO:0000123;HPO:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HPO:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HPO:0000123,sample1/HPO:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -p in.ped -t sample0/HPO:0000123;HPO:0000234,sample1/HPO:0000345 -f -d -k
```
