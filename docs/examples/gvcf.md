# gVCF

The gvcf workflow can be run when starting with gvcf files.

## Samplesheet

```
family_id	individual_id	paternal_id	maternal_id	sex	affected	proband	gvcf	cram
FAM0	HG002	HG003	HG004	male	true	true	HG002.illumina.wes.chr20.g.vcf.gz	illumina_WES_GRCh38_chr20.cram
FAM0	HG003			male	false		HG003.illumina.wes.chr20.g.vcf.gz	illumina_WES_GRCh38_chr20.cram
FAM0	HG004			female	false		HG004.illumina.wes.chr20.g.vcf.gz	illumina_WES_GRCh38_chr20.cram
```

The required cram and gvcf files can be downloaded from the [test resources](https://download.molgeniscloud.org/downloads/vip/test/resources/) folder.


## Run the pipeline

```bash
vip.sh --workflow gvcf --input samplesheet.tsv --output path/to/output/folder
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
│   ├── vip_sample_classifications.vcf.gz.csi
│   ├── vip.vcf.gz
│   └── vip.vcf.gz.csi
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
