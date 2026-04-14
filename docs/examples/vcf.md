# VCF

The vcf workflow can be run when starting with vcf files.

## Samplesheet

```
individual_id	sex	proband	affected	vcf
SAMPLE0	male	true	true	chd7.tsv
```

The required vcf file can be downloaded from [GitHub](https://github.com/molgenis/vip/tree/main/test/suites/vcf/resources).

## Run the pipeline

```bash
vip.sh --workflow vcf --input samplesheet.tsv --output path/to/output/folder
```

## Output files

```
.
├── intermediates
│   ├── vip_annotations.vcf.gz
│   ├── vip_annotations.vcf.gz.csi
│   ├── vip_classifications.vcf.gz
│   ├── vip_classifications.vcf.gz.csi
│   ├── vip.db
│   ├── vip_sample_classifications.vcf.gz
│   └── vip_sample_classifications.vcf.gz.csi
├── log
│   ├── nxf.log
│   ├── nxf_report.html
│   ├── nxf_timeline.html
│   ├── slurm_job.err
│   └── slurm_job.out
├── samplesheet.tsv
├── tmp
│   ├── nextflow
│   ├── nxf.temp
│   └── nxf.work
├── vip.html
├── vip.vcf.gz
└── vip.vcf.gz.csi
```
