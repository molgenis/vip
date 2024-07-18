# Workflow
VIP consists of four workflows depending on the type of input data: fastq, bam/cram, gvcf or vcf.
The `fastq` workflow is an extension of the `cram` workflow. The `cram` and `gvcf` workflows are extensions of the `vcf` workflow.
The `vcf` workflow produces the pipeline outputs as described [here](./output.md).
The following sections provide an overview of the steps of each of these workflows. 

## FASTQ
The `fastq` workflow consists of the following steps:

1. Parallelize sample sheet per sample and for each sample
2. Quality reporting and preprocessing using [fastp](https://github.com/OpenGene/fastp)
3. Alignment using [minimap2](https://github.com/lh3/minimap2) producing a `cram` file per sample
4. In case of multiple fastq files per sample, concatenate the cram output files
5. Continue with step 3. of the `cram` workflow

For details, see [here](https://github.com/molgenis/vip/blob/main/vip_fastq.nf).

## CRAM
The `cram` workflow consists of the following steps:

1. Parallelize sample sheet per sample and for each sample
2. Create validated, indexed `.bam` file from `bam/cram/sam` input
3. Discover short tandem repeats and publish as intermediate result.
    1. Using [ExpansionHunter](https://github.com/Illumina/ExpansionHunter) for Illumina short read data.
    2. Using this [fork of Straglr](https://github.com/molgenis/straglr) for PacBio and Nanopore long read data, this is a fork of this fork(https://github.com/philres/straglr) and is chosen over the original [Straglr](https://github.com/bcgsc/straglr) because of the VCF output that enables VIP to combine it with the SV and SNV data in the VCF workflow.
4. Discover copy number variants for for PacBio and Nanopore long read data using [Spectre](https://github.com/fritzsedlazeck/Spectre) data and publish as intermediate result.
5. Parallelize cram in chunks consisting of one or more contigs and for each chunk
    1. Perform short variant calling with [DeepVariant](https://github.com/google/deepvariant) producing a `gvcf` file per chunk per sample, the gvcfs of the samples in a project are than merged to one vcf per project (using [GLnexus](https://github.com/dnanexus-rnd/GLnexus).
    2. Perform structural variant calling with [Manta](https://github.com/Illumina/manta) or [cuteSV](https://github.com/tjiangHIT/cuteSV) producing a `vcf` file per chunk per project.
6. Concatenate short variant calling and structural variant calling `vcf` files per chunk per sample
7. Continue with step 3. of the `vcf` workflow

For details, see [here](https://github.com/molgenis/vip/blob/main/vip_cram.nf).

## gVCF
The `gvcf` workflow consists of the following steps:

1. For each project in the sample sheet
2. Create validated, indexed `.g.vcf.gz` file from `bcf/bcf.gz/bcf.bgz/gvcf/gvcf.gz/gvcf.bgz/vcf/vcf.gz/vcf.bgz` inputs
3. Merge `.g.vcf.gz` files using [GLnexus](https://github.com/dnanexus-rnd/GLnexus) resulting in one `vcf.gz` per project
4. Continue with step 3. of the `vcf` workflow

For details, see [here](https://github.com/molgenis/vip/blob/main/vip_gvcf.nf).
 
## VCF
The `vcf` workflow consists of the following steps:

1. For each project in the sample sheet
2. Create validated, indexed `.vcf.gz` file from `bcf|bcf.gz|bcf.bgz|vcf|vcf.gz|vcf.bgz` input
3. Chunk `vcf.gz` files and for each chunk
    1. Normalize
    2. Annotate
    3. Classify
    4. Filter
    5. Perform inheritance matching
    6. Classify in the context of samples
    7. Filter in the context of samples
4. Concatenate chunks resulting in one `vcf.gz` file per project
5. If `cram` data is available slice the `cram` files to only keep relevant reads
6. Create report

For details, see [here](https://github.com/molgenis/vip/blob/main/vip_vcf.nf).
