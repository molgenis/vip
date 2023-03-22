# Input
The `--input` value is a tab-separated file (sample-sheet) with each row describing the data and metadata of a sample.

A minimal sample-sheet for the `vcf` workflow could look like this:

| individual_id  | vcf            |
|----------------|----------------|
| sample0        | sample0.vcf.gz |
| sample1        | sample1.vcf.gz |
| sample2        | sample2.vcf.gz |

Sample-sheet values are case sensitive. Columns can contain values of different types:

| type        | description                                                  | 
|-------------|--------------------------------------------------------------|
| boolean     | allowed values: [``true``, ``false``]                        |
| enum        | categorical value                                            |
| file        | absolute file path or file path relative to the sample sheet |
| file list   | comma-separated list of file paths                           |
| string      | text                                                         |
| string list | comma-separated list of strings                              |

The following sections describe the columns that can be used in every sample-sheet followed by [workflow](workflow.md) specific columns.   

## Columns
| column                | type            | required | default                 | description                             |                                        
|-----------------------|-----------------|----------|-------------------------|-----------------------------------------|
| ``project_id``        | ``string``      |          | ``vip``                 | project identifier                      |
| ``family_id``         | ``string``      |          | ``vip_fam<index>``      | family identifier                       |
| ``individual_id``     | ``string``      | yes      |                         | sample identifier of the individual     |
| ``paternal_id``       | ``string``      |          |                         | sample identifier of the father         |
| ``maternal_id``       | ``string``      |          |                         | sample identifier of the mother         |
| ``sex``               | ``enum``        |          | unknown sex             | ``values: [male,female]``               |
| ``affected``          | ``boolean``     |          | unknown affected status | whether the individual is affected      |
| ``proband``           | ``boolean``     |          | depends<sup>1</sup>     | individual being reported on            |
| ``hpo_ids``           | ``string list`` |          |                         | regex: `/HP:\d{7}/`                     |
| ``assembly``          | ``enum``        |          | ``GRCh38``              | allowed values: [``GRCh37``,``GRCh38``] |
| ``sequencing_method`` | ``enum``        |          | ``WGS``                 | allowed values: [``WES``,``WGS``]       |

<sup>1</sup> Exception: if no probands are defined in the sample-sheet then all samples are considered to be probands.

## Columns: FASTQ
| column                  | type          | required        | default      | description                                                                                        |
|-------------------------|---------------|-----------------|--------------|----------------------------------------------------------------------------------------------------|
| ``fastq``               | ``file list`` | yes<sup>2</sup> |              | allowed file extensions: [``fastq``, ``fastq.gz``, ``fq``, ``fq.gz``]. single-reads file(s)        |
| ``fastq_r1``            | ``file list`` | yes<sup>2</sup> |              | allowed file extensions: [``fastq``, ``fastq.gz``, ``fq``, ``fq.gz``]. paired-end reads file(s) #1 |
| ``fastq_r2``            | ``file list`` | yes<sup>2</sup> |              | allowed file extensions: [``fastq``, ``fastq.gz``, ``fq``, ``fq.gz``]. paired-end reads file(s) #2 |
| ``sequencing_platform`` | ``enum``      |                 | ``illumina`` | allowed values: [``illumina``,``nanopore``]                                                        |

<sup>2</sup> Either the `fastq` or the ``fastq_r1`` and ``fastq_r2`` are required.  

## Columns: CRAM
| column                  | type     | required | default      | description                                  |
|-------------------------|----------|----------|--------------|----------------------------------------------|
| ``cram``                | ``file`` | yes      |              | allowed file extensions: [``bam``, ``cram``] |
| ``sequencing_platform`` | ``enum`` |          | ``illumina`` | allowed values: [``illumina``,``nanopore``]  |

## Columns: VCF
| column   | type     | required | default | description                                                                                   |
|----------|----------|----------|---------|-----------------------------------------------------------------------------------------------|
| ``vcf``  | ``file`` | yes      |         | allowed file extensions: [``vcf``, ``vcf.gz``, ``vcf.bgz``, ``bcf``, ``bcf.gz``, ``bcf.bgz``] |
| ``cram`` | ``file`` |          |         | allowed file extensions: [``bam``, ``cram``]                                                  |
