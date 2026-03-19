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
│   ├── vip_0.vcf.gz
│   ├── vip_0.vcf.gz.csi
│   ├── vip_0.vcf.gz.stats
│   ├── vip_10.vcf.gz
│   ├── vip_10.vcf.gz.csi
│   ├── vip_10.vcf.gz.stats
│   ├── vip_11.vcf.gz
│   ├── vip_11.vcf.gz.csi
│   ├── vip_11.vcf.gz.stats
│   ├── vip_12.vcf.gz
│   ├── vip_12.vcf.gz.csi
│   ├── vip_12.vcf.gz.stats
│   ├── vip_13.vcf.gz
│   ├── vip_13.vcf.gz.csi
│   ├── vip_13.vcf.gz.stats
│   ├── vip_14.vcf.gz
│   ├── vip_14.vcf.gz.csi
│   ├── vip_14.vcf.gz.stats
│   ├── vip_15.vcf.gz
│   ├── vip_15.vcf.gz.csi
│   ├── vip_15.vcf.gz.stats
│   ├── vip_16.vcf.gz
│   ├── vip_16.vcf.gz.csi
│   ├── vip_16.vcf.gz.stats
│   ├── vip_1.vcf.gz
│   ├── vip_1.vcf.gz.csi
│   ├── vip_1.vcf.gz.stats
│   ├── vip_2.vcf.gz
│   ├── vip_2.vcf.gz.csi
│   ├── vip_2.vcf.gz.stats
│   ├── vip_3.vcf.gz
│   ├── vip_3.vcf.gz.csi
│   ├── vip_3.vcf.gz.stats
│   ├── vip_4.vcf.gz
│   ├── vip_4.vcf.gz.csi
│   ├── vip_4.vcf.gz.stats
│   ├── vip_5.vcf.gz
│   ├── vip_5.vcf.gz.csi
│   ├── vip_5.vcf.gz.stats
│   ├── vip_6.vcf.gz
│   ├── vip_6.vcf.gz.csi
│   ├── vip_6.vcf.gz.stats
│   ├── vip_7.vcf.gz
│   ├── vip_7.vcf.gz.csi
│   ├── vip_7.vcf.gz.stats
│   ├── vip_8.vcf.gz
│   ├── vip_8.vcf.gz.csi
│   ├── vip_8.vcf.gz.stats
│   ├── vip_9.vcf.gz
│   ├── vip_9.vcf.gz.csi
│   ├── vip_9.vcf.gz.stats
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
