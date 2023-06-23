# Nanopore
To run vip with nanopore data, just specify nanopore as the sequencing_platform in your sample sheet.
The other options for this field are "illumina" and "pacbio_hifi" and can be used in a similar manner.

## Samplesheet
See an example for the samplesheet below, the example show the samplesheet for a run starting from the cram, 
but the 'sequencing_platform' can also be used to achieve the same for a run with the fastq workflow.

```
individual_id	sequencing_platform	cram
your_sample_id	nanopore	path/to/your/nanopore.cram
```

## Run the pipeline
```bash
cd vip
vip --workflow cram --input path/to/samplesheet.tsv --output path/to/output/folder
```

For an example on how to generate output for FASTQ files using the Oxford Nanopore platform see [here](https://github.com/molgenis/vip/blob/main/test/test_fastq.sh#L9).