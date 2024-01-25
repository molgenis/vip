# POD5
To run vip with POD5 data, just specify the POD5 paths in your sample sheet.

## Samplesheet
See an example for the samplesheet below, the example shows the samplesheet for a run starting from the `pod5`.

```
individual_id	pod5
your_sample_id		path/to/your/data_1.pod5,path/to/your/data_2.pod5
```

## Run the pipeline
```bash
cd vip
vip --workflow pod5 --input path/to/samplesheet.tsv --output path/to/output/folder
```
