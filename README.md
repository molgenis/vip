# Variant Interpretation Pipeline

## Usage
```
usage: pipeline.sh -i <arg> -o <arg>

-i,  --input  <arg>        required: Input VCF file (.vcf or .vcf.gz).
-o,  --output <arg>        required: Output VCF file (.vcf or .vcf.gz).
-r,  --reference <arg>     optional: Reference sequence FASTA file (.fasta or .fasta.gz).
-b,  --probands <arg>      optional: Subjects being reported on (comma-separated VCF sample names).
-p,  --pedigree <arg>      optional: Pedigree file (.ped).
-t,  --phenotypes <arg>    optional: Phenotypes for input samples (see examples).
-f,  --force               optional: Override the output file if it already exists.
-k,  --keep                optional: Keep intermediate files.

--ann_vep                  optional: Variant Effect Predictor (VEP) options.
--args_preprocess          optional: Additional preprocessing module arguments.
--args_report              optional: Additional report module options for --args.
--flt_tree                 optional: Decision tree file (.json) that applies classes 'F' and 'T'.

examples:
  pipeline.sh -i in.vcf -o out.vcf
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -b sample0
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -p in.ped
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t HP:0000123;HP:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -t sample0/HP:0000123,sample1/HP:0000234
  pipeline.sh -i in.vcf.gz -o out.vcf.gz --ann_vep "--refseq --exclude_predicted --use_given_ref"
  pipeline.sh -i in.vcf.gz -o out.vcf.gz -r human_g1k_v37.fasta.gz -b sample0,sample1 -p in.ped -t sample0/HP:0000123;HP:0000234,sample1/HP:0000345 --ann_vep "--refseq --exclude_predicted --use_given_ref" --flt_tree custom_tree.json --args_report "--max_samples 10" --args_preprocess "--filter_read_depth -1" -f -k
```

## Usage: modules
Pipeline modules can be used separately, run one of the following scripts for usage information:
```
pipeline_preprocess.sh
pipeline_annotate.sh
pipeline_filter.sh
pipeline_report.sh
```
