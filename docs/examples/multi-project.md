# Multi-project

VIP can be used to analyse different projects in one run, producing output files per project.
To achieve this you just need to specify different projects in one samplesheet.

```
family_id  individual_id	paternal_id	maternal_id	sex affected	proband	sequencing_platform	fastq		fastq_r1		fastq_r2
vip0	fam0	individual0	individual1			male	true	true	nanopore		path/to/vip0.fastq.gz
vip0	fam0	individual1					female	false	false	nanopore		path/to/vip1.fastq.gz
vip1	fam1	individual2	individual3 	individual4	male	false	false	paacbio_hifi		path/to/vip2.fastq.gz
vip1	fam1	individual3					male	false	false	pacbio_hifi		path/to/vip3.fastq.gz
vip1	fam1	individual4					female	false	true	pacbio_hifi		path/to/vip4.fastq.gz
vip2	fam2	individual5					male	true	true	illumina				/vip5_1.fastq.gz	/vip5_2.fastq.gz
```

## Run the pipeline

```bash
vip.sh --workflow fastq --input path/to/samplesheet.tsv --output path/to/output/folder
```

For a working example on how to generate output for multiple projects
see [here](https://github.com/molgenis/vip/blob/main/test/test_vcf.sh#L82).
