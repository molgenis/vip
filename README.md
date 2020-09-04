# Variant Interpretation Pipeline

## Usage
```
usage: pipeline.sh -i <arg> -o <arg> [-p <arg>] [-f] [-k]

-i, --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o, --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-r, --reference <arg>     optional: Reference sequence FASTA file (.fasta or .fasta.gz).
-p, --pedigree <arg>      optional: Pedigree file (.ped).
-t, --phenotypes <arg>    optional: Phenotypes for input samples (see examples).
-f, --force               optional: Override the output file if it already exists.
-k, --keep                optional: Keep intermediate files.

examples:
  pipeline.sh -i in.vcf -o out.vcf
  pipeline.sh -i in.vcf -o out.vcf -r human_g1k_v37.fasta.gz
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -p in.ped
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123;HP:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123,sample1/HPO:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz -p in.ped -t sample0/HP:0000123;HP:0000234,sample1/HP:0000345 -f -k
```

## Usage: modules
Pipeline modules can be used separately, run one of the following scripts for usage information:
```
pipeline_preprocess.sh
pipeline_annotate.sh
pipeline_filter.sh
pipeline_report.sh
```
