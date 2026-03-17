# Workflows

VIP can be run from four different workflows. Below are examples for each workflow with samplesheets displaying different columns that can be used.
Note that the samplesheet needs to be a tab separated file.
Please see [Input](../usage/input.md) for more info about the samplesheet and a list of columns that need to be and can be used for each workflow.

Note that you can also inspect the tests provided with VIP in the `test/suites/` subfolders to get a better idea on creating samplesheets for different workflows.
These tests can be executed to also give an idea of what the output looks like. Note that to run these tests, you might need to set the appropriate environment variables of modify the test samplesheets.

## FASTQ

The fastq workflow can be run when providing fastq files as input.
In the example samplesheet below, we have three different projects and three different families consisting of various sizes and sequenced with different sequencing platforms.
VIP will run the different projects in one run and produce output files per project.
The samplesheet indicates for each affected individual who his parents are which is then used for duo or trio variant calling and further analyses (such as inheritance matcher).
We also added HPO terms for two affected individuals. This will select found variants associated with the HPO terms by default in the resulting VIP report.

### Samplesheet

| project_id | family_id | individual_id | paternal_id | maternal_id | sex    | affected | proband | hpo_ids                          | sequencing_platform | fastq                     |
|------------|-----------|---------------|-------------|-------------|--------|-------------------------------------------------------|---------------------|---------------------------|
| vip0       | fam01     | sample01      |             |             | female | true     | true    | HP:0004383,HP:0045017,HP:0001627 | pacbio_hifi         | path/to/sample01.fastq.gz |
| vip1       | fam02     | sample02      | sample03    | sample04    | male   | true     | true    |                                  | nanopore            | path/to/sample02.fastq.gz |
| vip1       | fam02     | sample03      |             |             | male   |          |         |                                  | nanopore            | path/to/sample03.fastq.gz |
| vip1       | fam02     | sample04      |             |             | female |          |         |                                  | nanopore            | path/to/sample04.fastq.gz |
| vip2       | fam03     | sample05      |             | sample06    | male   | true     | true    | HP:0012103                       | pacbio_hifi         | path/to/sample05.fastq.gz |
| vip2       | fam03     | sample06      |             |             | female |          |         |                                  | pacbio_hifi         | path/to/sample06.fastq.gz |

### Copy the samplesheet

```
project_id	family_id	individual_id	paternal_id	maternal_id	sex	affected	proband	hpo_ids	sequencing_platform	fastq
vip0	fam01	sample01			female	TRUE	TRUE	HP:0004383,HP:0045017,HP:0001627	pacbio_hifi	path/to/sample01.fastq.gz
vip1	fam02	sample02	sample03	sample04	male	TRUE	TRUE		nanopore	path/to/sample02.fastq.gz
vip1	fam02	sample03			male				nanopore	path/to/sample03.fastq.gz
vip1	fam02	sample04			female				nanopore	path/to/sample04.fastq.gz
vip2	fam03	sample05		sample06	male	TRUE	TRUE	HP:0012103	pacbio_hifi	path/to/sample05.fastq.gz
vip2	fam03	sample06			female				pacbio_hifi	path/to/sample06.fastq.gz
```


### Run the pipeline

```bash
vip.sh --workflow fastq --input path/to/samplesheet --output path/to/output/folder
```

## CRAM

The CRAM workflow can be run when providing CRAM or BAM files as input. This can be useful if you want VIP to further analyse already mapped data.
The example samplesheet below has, like the fastq samplesheet above, three projects and three families.
Because we did not add sequencing_platform it will be assumed that the files have mapped reads from a nanopore sequencer, but the `sequencing_platform` column can be added to specify one of three platforms: `nanopore, illmuna, pacbio_hifi`.
Two samples have a bed file in the regions column. This will filter the cram after mapping to the specified chromosomes/regions and is also used in further analyses. Note that in this case the parental data will also be filtered as they are part of the same project id.

### Samplesheet

| project_id | family_id | individual_id | paternal_id | maternal_id | sex    | cram                  | regions           |
|------------|-----------|---------------|-------------|-------------|--------|-------------------------------------------|
| vip0       | fam01     | sample01      |             |             | female | path/to/sample01.cram | path/to/chr10.bed |
| vip1       | fam02     | sample02      | sample03    | sample04    | male   | path/to/sample02.cram |                   |
| vip1       | fam02     | sample03      |             |             | male   | path/to/sample03.cram |                   |
| vip1       | fam02     | sample04      |             |             | female | path/to/sample04.cram |                   |
| vip2       | fam03     | sample05      |             | sample06    | male   | path/to/sample05.cram | path/to/chrm.bed  |
| vip2       | fam03     | sample06      |             |             | female | path/to/sample06.cram |                   |

### Copy the samplesheet

```
project_id	family_id	individual_id	paternal_id	maternal_id	sex	cram	regions
vip0	fam01	sample01			female	path/to/sample01.cram	path/to/chr10.bed
vip1	fam02	sample02	sample03	sample04	male	path/to/sample02.cram	
vip1	fam02	sample03			male	path/to/sample03.cram	
vip1	fam02	sample04			female	path/to/sample04.cram	
vip2	fam03	sample05		sample06	male	path/to/sample05.cram	path/to/chrm.bed
vip2	fam03	sample06			female	path/to/sample06.cram	
```

### Run the pipeline

```bash
vip.sh --workflow cram --input path/to/samplesheet.tsv --output path/to/output/folder
```


## GVCF

The gVCF workflow can be run when you provide VIP with the gVCF files, which will then be further annotated, classified and filtered.
Starting with gVCF files can be useful to also take into account whether the variant of patients was also found in one or both of their parents or not (as we can do with fam1 and fam2).
We added the assembly column to let VIP know that the variants in the gVCF file were called on reference genome GRCh38.

### Samplesheet

| project_id | family_id | individual_id | paternal_id | maternal_id | sex    | assembly | gvcf                   |
|------------|-----------|---------------|-------------|-------------|--------|----------|------------------------|
| vip0       | fam01     | sample01      |             |             | female | GRCh38   | path/to/sample01.g.vcf |
| vip1       | fam02     | sample02      | sample03    | sample04    | male   | GRCh38   | path/to/sample02.g.vcf |
| vip1       | fam02     | sample03      |             |             | male   | GRCh38   | path/to/sample03.g.vcf |
| vip1       | fam02     | sample04      |             |             | female | GRCh38   | path/to/sample04.g.vcf |
| vip2       | fam03     | sample05      |             | sample06    | male   | GRCh38   | path/to/sample05.g.vcf |
| vip2       | fam03     | sample06      |             |             | female | GRCh38   | path/to/sample06.g.vcf |

### Copy the samplesheet

```
project_id	family_id	individual_id	paternal_id	maternal_id	sex	assembly	gvcf
vip0	fam01	sample01			female	GRCh38	path/to/sample01.g.vcf
vip1	fam02	sample02	sample03	sample04	male	GRCh38	path/to/sample02.g.vcf
vip1	fam02	sample03			male	GRCh38	path/to/sample03.g.vcf
vip1	fam02	sample04			female	GRCh38	path/to/sample04.g.vcf
vip2	fam03	sample05		sample06	male	GRCh38	path/to/sample05.g.vcf
vip2	fam03	sample06			female	GRCh38	path/to/sample06.g.vcf
```

### Run the pipeline

```bash
vip.sh --workflow gvcf --input path/to/samplesheet.tsv --output path/to/output/folder
```


## VCF

The VCF workflow can be run when providing VCF files as input and can be useful to further annotate, classify and filter previously called variants.
Like the previous samplesheets, the one below notes down the details about the samples and familial relations (parental and maternal ids).
We furthermore added the assembly to let VIP know the variants were called on genome reference GRCh38.
We also added the cram files for each sample. This allows the VIP report to also include the reads used to call the variant. When viewing a variant in the report, the alignment can than also be viewed for more details.

### Samplesheet

| project_id | family_id | individual_id | paternal_id | maternal_id | sex    | assembly | vcf                     | cram                  |
|------------|-----------|---------------|-------------|-------------|--------|------------------------------------|-----------------------|
| vip0       | fam01     | sample01      |             |             | female | GRCh38   | path/to/sample01.vcf.gz | path/to/sample01.cram |
| vip1       | fam02     | sample02      | sample03    | sample04    | male   | GRCh38   | path/to/sample02.vcf.gz | path/to/sample02.cram |
| vip1       | fam02     | sample03      |             |             | male   | GRCh38   | path/to/sample03.vcf.gz | path/to/sample03.cram |
| vip1       | fam02     | sample04      |             |             | female | GRCh38   | path/to/sample04.vcf.gz | path/to/sample04.cram |  
| vip2       | fam03     | sample05      |             | sample06    | male   | GRCh38   | path/to/sample05.vcf.gz | path/to/sample05.cram |
| vip2       | fam03     | sample06      |             |             | female | GRCh38   | path/to/sample06.vcf.gz | path/to/sample06.cram |

### Copy the samplesheet

```
project_id	family_id	individual_id	paternal_id	maternal_id	sex	assembly	vcf	cram
vip0	fam01	sample01			female	GRCh38	path/to/fam01.vcf	path/to/sample01.cram
vip1	fam02	sample02	sample03	sample04	male	GRCh38	path/to/fam02.vcf	path/to/sample02.cram
vip1	fam02	sample03			male	GRCh38	path/to/fam02.vcf	path/to/sample03.cram
vip1	fam02	sample04			female	GRCh38	path/to/fam02.vcf	path/to/sample04.cram
vip2	fam03	sample05		sample06	male	GRCh38	path/to/fam03.vcf	path/to/sample05.cram
vip2	fam03	sample06			female	GRCh38	path/to/fam03.vcf	path/to/sample06.cram
```

### Run the pipeline

```bash
vip.sh --workflow vcf --input path/to/samplesheet.tsv --output path/to/output/folder
```