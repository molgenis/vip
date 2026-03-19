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
│   ├── vip_sample_classifications.vcf.gz
│   └── vip_sample_classifications.vcf.gz.csi
├── job.err
├── job.out
├── nxf_report.html
├── nxf_timeline.html
├── samplesheet.tsv
├── vip.db
├── vip.html
├── vip.vcf.gz
└── vip.vcf.gz.csi
```
