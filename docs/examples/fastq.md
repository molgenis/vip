# FastQ

The fastq workflow can be run when starting with fastq files.

## The samplesheet

```
individual_id	sequencing_platform	fastq	regions
HG002	nanopore	m54238_180628_014238_s0_10000.Q20.part_001.fastq.gz,m54238_180628_014238_s0_10000.Q20.part_002.fastq.gz	nanopore.bed
```

The required fastq file can be downloaded from the [test resources](https://download.molgeniscloud.org/downloads/vip/test/resources/) folder.
The required bed and config files can be downloaded from [GitHub](https://github.com/molgenis/vip/tree/main/test/suites/fastq/resources).

## Run the pipeline

```bash
vip.sh --workflow fastq --input samplesheet.tsv --config nanopore.cfg --output path/to/output/folder
```

## Output files

```
.
├── coverage
│   ├── vip_fam0_HG002_mosdepth.global.dist.txt
│   ├── vip_fam0_HG002_mosdepth.per-base.bed.gz
│   ├── vip_fam0_HG002_mosdepth.per-base.bed.gz.csi
│   ├── vip_fam0_HG002_mosdepth.region.dist.txt
│   ├── vip_fam0_HG002_mosdepth.regions.bed.gz
│   ├── vip_fam0_HG002_mosdepth.regions.bed.gz.csi
│   ├── vip_fam0_HG002_mosdepth.summary.txt
│   ├── vip_fam0_HG002_mosdepth.thresholds.bed.gz
│   └── vip_fam0_HG002_mosdepth.thresholds.bed.gz.csi
├── intermediates
│   ├── fastp
│   │   ├── vip_fam0_HG002_report.html
│   │   └── vip_fam0_HG002_report.json
│   ├── HG002_snv.g.vcf.gz
│   ├── HG002_snv.g.vcf.gz.csi
│   ├── HG002_snv.g.vcf.gz.stats
│   ├── vip_annotations.vcf.gz
│   ├── vip_annotations.vcf.gz.csi
│   ├── vip_classifications.vcf.gz
│   ├── vip_classifications.vcf.gz.csi
│   ├── vip_complete_snv.vcf.gz
│   ├── vip_complete_snv.vcf.gz.csi
│   ├── vip_complete_snv.vcf.gz.stats
│   ├── vip_fam0_HG002_cnv.vcf.gz
│   ├── vip_fam0_HG002_cnv.vcf.gz.csi
│   ├── vip_fam0_HG002_cnv.vcf.gz.stats
│   ├── vip_fam0_HG002.cram
│   ├── vip_fam0_HG002.cram.crai
│   ├── vip_fam0_HG002.cram.stats
│   ├── vip_fam0_HG002_str.tsv
│   ├── vip_fam0_HG002_str.vcf.gz
│   ├── vip_fam0_HG002_str.vcf.gz.csi
│   ├── vip_fam0_HG002_str.vcf.gz.stats
│   ├── vip_fam0_HG002_sv.vcf.gz
│   ├── vip_fam0_HG002_sv.vcf.gz.csi
│   ├── vip_fam0_HG002_sv.vcf.gz.stats
│   ├── vip_mtdnasnv.vcf.gz
│   ├── vip_mtdnasnv.vcf.gz.csi
│   ├── vip_mtdnasnv.vcf.gz.stats
│   ├── vip_sample_classifications.vcf.gz
│   ├── vip_sample_classifications.vcf.gz.csi
│   ├── vip_snv.vcf.gz
│   ├── vip_snv.vcf.gz.csi
│   ├── vip_snv.vcf.gz.stats
│   ├── vip.vcf.gz
│   ├── vip.vcf.gz.csi
│   └── vip.vcf.gz.stats
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
